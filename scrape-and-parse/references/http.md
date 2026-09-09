# HTTP: status handling, retries, sessions

## Three kinds of failure, three responses

Every failed request is one of these, and a scraper that treats them alike either gives up on
a two-hour outage in fifteen seconds or hammers a 404 for an hour.

| kind | examples | what it means | response |
|---|---|---|---|
| **connection** | name resolution, connect refused, read timeout, reset, `RemoteDisconnected`, `IncompleteRead`, SSL | the server was never asked, or never answered | wait it out: back off from ~5 s doubling to a 10-minute cap, for hours; never let a worker die on it |
| **throttle** | 429; sometimes 503 with `Retry-After` | the server asked you to slow down | honour `Retry-After`; else long fixed waits (60, 180, 420 s); reduce concurrency for the rest of the run |
| **other HTTP errors** | 400, 403, 404, 410, 451, 5xx | meaning depends on source, authentication, and response body | distinguish invalid requests, access limits, permanent absence, and transient failures; retain recoverable failures for resume |

HTTP success is not proof of a record or a permanent miss. Treat an empty 200 or
204 as `miss` only when verified source behavior uses it to mean no such record.
A 200 error page can indicate malformed requests, expired sessions, throttling,
or an outage. Preserve it as `portal-error` or a more specific failure, diagnose
its meaning, and use a bounded recovery policy. A rising miss/error share is a
reason to inspect response bodies and source coverage before continuing.

Where the outage was, 8 Sept 2026: `bhunaksha.rajasthan.gov.in` stopped resolving for seven
hours while the Odisha crawl on the same machine ran normally. The Rajasthan client retried four
times over fifteen seconds and raised; the worker's session rebuild then raised inside the
`except`, and the thread died. A third of the day's requests were lost to a failure the client
could have slept through.

## Use a retry library, not a loop

`stamina` (26.1.0, April 2026; built on `tenacity`) gives typed, instrumented retries with
jittered exponential back-off and per-exception-class policy in a decorator or a context
manager. `tenacity` (9.1.4, Feb 2026) is the lower-level choice. Both are maintained; check
PyPI before pinning. The one thing a hand-written loop always gets wrong is the taxonomy above,
so express it as policy:

```python
import stamina, requests

@stamina.retry(on=(requests.ConnectionError, requests.Timeout), attempts=None,
               timeout=2 * 3600, wait_initial=5, wait_max=600)
def post(session, url, form):
    r = session.post(url, data=form, timeout=60)
    if r.status_code in (429, 503):
        raise Throttled(r.headers.get("Retry-After"))   # handled by a second, slower policy
    return r
```

`attempts=None, timeout=...` is the "wait it out for hours" policy; keep permanent statuses
outside the retried exception set so they surface immediately. For urllib-only code the same
taxonomy lives in `odisha-ror/bhulekh.py`: `RETRYABLE`, `THROTTLE_BACKOFF`, `PERMANENT_STATUS`.

## What the older repos got wrong, so it is not repeated

`electoral_rolls/tools/utils.py` carries four near-duplicate downloaders with `verify=False`,
an unverified SSL context, and a `while True` retry with no cap; `mnregra` checks
`status_code == 200` and otherwise prints the exception and continues; `up-2023` decides a
download failed by `len(content) < 20000`. Each of these is one of the three failure kinds
handled as if it were another. TLS verification stays on (ship `certifi` if the portal's chain
is odd), retries are bounded in time, and the success test is the content (`%PDF`, a page
count, the field you came for), not the size.

## Sessions

- **One `requests.Session` per worker**, headers set once (a real User-Agent, the portal's own
  `Referer`, `X-Requested-With: XMLHttpRequest` for AJAX-style REST). Keep-alive is the
  difference between 1 and 3 requests a second on a slow portal.
- **Open the session by fetching the landing page.** ASP.NET portals issue the session cookie
  there; a direct GET of an inner page redirects to an error page (Odisha) or the home page
  (Rajasthan).
- **Measure whether concurrency helps before adding workers.** Six threads on one session,
  six threads on six sessions, one thread: if aggregate throughput barely moves, the portal
  serialises per client or globally and the lever is latency (a VM near the server) or more
  IPs, not threads. Rajasthan: 0.6 → 1.3 → 1.0 requests a second for those three.
- **Rate-limit per worker with a minimum gap**, not a global token bucket; it is simpler and
  the portal, not you, sets the ceiling.
- **Pin nothing you did not measure.** No `sleep(0.5)` folklore; the pause is a flag with a
  measured default.

## ASP.NET WebForms portals

Half the Indian state portals are WebForms pages driven by `__doPostBack`. The pattern:

1. GET the page, collect every `<input type="hidden">` (`__VIEWSTATE`, `__EVENTVALIDATION`,
   CSRF fields) and post them back with `__EVENTTARGET` set to the control that changed.
2. Each dropdown fires a postback that returns the whole page with the next dropdown filled.
   Replay the cascade in order; never skip a level, the server validates the sequence.
3. **Values are opaque and load-bearing.** Odisha's khatiyan option value is space-padded to 30
   characters and trimming it returns an error page. Post exactly what the page gave you.
4. **One session may serve exactly one record.** Odisha renders one RoR per session and every
   cheaper reuse fails; the cost is a six-request cascade per record. Test reuse once, early,
   and write down the answer in the README.
5. Some pages only look gated: the Rajasthan map's captcha is generated and checked in browser
   JavaScript and never reaches the server. Read the page's JS before assuming a wall.

## REST behind a map or an app

When the portal is a map (OpenLayers, Leaflet) or a mobile app, the REST layer underneath is
usually simpler and unauthenticated. Find it by reading the page's `index.js` for
`$.post(`/`fetch(` calls and replaying them with the exact parameter shapes: Rajasthan's level
codes must be sent as `01,002,0745,` with a trailing comma, or the call returns empty lists.

## Portal totals are your only completeness check

Landing pages often print counts (Odisha: 30 districts, 317 tahsils, 51,796 villages,
20,432,717 khatiyans). Assert your enumeration against them rather than printing them; a
listing that comes back 0.05% high with no duplicates is complete, one that comes back 30%
low has skipped a level.
