# Downloader

Downloader for streaming files indexed in an M3U8 file.

## Prerequisites
CORS needs to be disabled for this downloader to work with certain streaming providers.
Recommended plug-in:
* https://chrome.google.com/webstore/detail/moesif-origin-cors-change/digfbfaphojjndkpccljibejjbppifbc?hl=en
  * Set `Access-Control-Allow-Origin` to the URL of this program (no wildcards!)
  * Set `Access-Control-Allow-Credentials` to `true`

## Related Projects
### NHL.DL
* https://github.com/caseyfw/nhldl
* https://www.reddit.com/r/NHLStreams/comments/45coy2/i_made_a_script_for_downloading_streams_not/

## TO-DOs
* Use parts of m3u8 URL for the filename (do not use basename only as the path contains more information)
* UI improvements:
  * Disable Download button when no URL is entered
  * Hide download bar before download starts
  * Hide failed when zero; change download bar color when non-zero
  * Allow to reload failed segments
* Check feasibility of searching m3u8 files from the app
