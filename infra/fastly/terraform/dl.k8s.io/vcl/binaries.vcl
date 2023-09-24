sub vcl_recv {
  # configure purges to require api authentication:
  # https://docs.fastly.com/en/guides/authenticating-api-purge-requests
  #
  if (req.method == "FASTLYPURGE") {
      set req.http.Fastly-Purge-Requires-Auth = "1";
  }

  # Prevent edge from caching stale content served from shield
  # https://developer.fastly.com/learning/concepts/stale/#shielding-considerations
  if (fastly.ff.visits_this_service != 0) {
    set req.max_stale_while_revalidate = 0s;
  }

#FASTLY recv

  # don't bother doing a cache lookup for a request type that isn't cacheable
  if (req.method != "HEAD" && req.method != "GET" && req.method != "FASTLYPURGE") {
    return(pass);
  }
  return(lookup);
}

sub vcl_fetch {
  /* handle 5XX (or any other unwanted status code) */
  if (beresp.status >= 500 && beresp.status < 600) {
    /* deliver stale if the object is available */
    if (stale.exists) {
      return(deliver_stale);
    }

    if (req.restarts < 1 && (req.request == "GET" || req.request == "HEAD")) {
      restart;
    }

    set beresp.cacheable = false;
    set beresp.ttl = 0s;
    /* else go to vcl_error to deliver a synthetic */
  error beresp.status;
  }

  if (beresp.http.Surrogate-Control !~ "(stale-while-revalidate|stale-if-error)") {
    set beresp.stale_if_error = 31536000s; // 1 year
    set beresp.stale_while_revalidate = 60s; // 1 minute
  }

  # TODO: Drop this when the origin(GCS bucket) is owned by the community
  # See: https://github.com/kubernetes/k8s.io/issues/2396
  if (req.url.path ~ "^/release/") {
    set beresp.http.Cache-Control = "private, no-store"; # Don't cache in the browser
    set beresp.ttl = 30d;
    set beresp.ttl -= std.atoi(beresp.http.Age);
    return (deliver);
  }

#FASTLY fetch
  if ((beresp.status == 500 || beresp.status == 503) && req.restarts < 1 && (req.method == "GET" || req.method == "HEAD")) {
    restart;
  }

  if (req.restarts > 0) {
    set beresp.http.Fastly-Restarts = req.restarts;
  }

  if (beresp.http.Set-Cookie) {
    set req.http.Fastly-Cachetype = "SETCOOKIE";
    return(pass);
  }

  if (beresp.http.Cache-Control ~ "private") {
    set req.http.Fastly-Cachetype = "PRIVATE";
    return(pass);
  }

  if (beresp.http.Expires || beresp.http.Surrogate-Control ~ "max-age" || beresp.http.Cache-Control ~ "(s-maxage|max-age)") {
    # keep the ttl here
  } else {
    # apply the default ttl
    set beresp.ttl = 3600s;
  }

  return(deliver);
}

sub vcl_hit {
#FASTLY hit

    # If the object we have isn't cacheable, then just serve it directly
    # without going through any of the caching mechanisms.
    if (!obj.cacheable) {
        return(pass);
    }

    return(deliver);
}

sub vcl_deliver {

#FASTLY deliver
  return(deliver);
}

sub vcl_miss {
#FASTLY miss
  return(fetch);
}

sub vcl_error {
#FASTLY error

  /* handle 503s */
  if (obj.status >= 500 && obj.status < 600) {
    /* deliver stale object if it is available */
    if (stale.exists) {
      return(deliver_stale);
    }
    /* otherwise, return a synthetic */

    # Handle our "error" conditions which are really just ways to set synthetic

    # responses.
    if (obj.status == 603) {
        set obj.status = 403;
        set obj.response = "SSL is required";
        set obj.http.Content-Type = "text/plain; charset=UTF-8";
        synthetic {"SSL is required."};
        return (deliver);
    }

    if (obj.status == 604) {
        set obj.status = 403;
        set obj.response = "SNI is required";
        set obj.http.Content-Type = "text/plain; charset=UTF-8";
        synthetic {"SNI is required."};
        return (deliver);
    }
  }
}

sub vcl_pass {
#FASTLY pass
}
