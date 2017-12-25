# Downloader

Downloader for streaming files indexed in an M3U8 file.

## Howto decode

Obtain Key:

	od -An -t x1 v-2.3 | tr -d ' ' 	

Decrypt:

	openssl enc -d -p -aes-128-cbc -nopad \
	            -in ENCRYPTED.ts -out OPEN.ts \
	            -K KEY -iv 06598c2f673f448aefe8745da6b862dd

Convert:

	ffmpeg -i all.ts -acodec copy -vcodec copy all.mp4

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

Cool stuff deleting commercial breaks!!
