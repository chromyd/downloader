# Freestream

Freestream (formerly dubbed "Downloader") downloads all HTTP stream files for a specified M3U playlist.

## Prerequisites
CORS needs to be disabled for Freestream to work with certain streaming providers.

Recommended plug-in:
- https://chrome.google.com/webstore/detail/resource-override/pkoacgokdfckfpndoffpifphamojphii

Plugin Configuration:
```
{
    "data": [
        {
            "id": "d1",
            "matchUrl": "*",
            "on": true,
            "rules": [
                {
                    "match": "https://mf.svc.nhl.com/ws/media/mf/v2.3/key/*",
                    "on": true,
                    "requestRules": "",
                    "responseRules": "set Access-Control-Allow-Origin: http%3A%2F%2Fdusan.freeshell.org",
                    "type": "headerRule"
                }
            ]
        }
    ],
    "v": 1
}
```

## TO-DOs
* Use parts of m3u8 URL for the filename (do not use basename only as the path contains more information)
* decrypt and concatenate in JavaScript (with [asmcrypto/asmcrypto.js](https://github.com/asmcrypto/asmcrypto.js) and [jimmywarting/StreamSaver.js](https://github.com/jimmywarting/StreamSaver.js))
* UI improvements:
  * Disable Download button when no URL is entered
  * Hide download bar before download starts
  * Hide failed when zero; change download bar color when non-zero
  * Allow to reload failed segments
* Download to a sub-directory to allow downloading/processing more than one source at a time
* Check feasibility of searching m3u8 files from the app
* Calculate and display ETA (remaining time)
* Add a button to paste the URL from clipboard
* Download process:
  * Disable Download button while download is in progress
  * Reset on next download (avoid page reload workaround)
