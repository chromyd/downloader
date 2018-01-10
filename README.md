# Freestream

Freestream downloads all HTTP stream files for a specified M3U playlist.

## Prerequisites
### Dependencies
```
brew install ffmpeg
brew install tesseract --HEAD
```
### Browser Plug-ins
#### Enable CORS
CORS needs to be enabled for Freestream to work with certain streaming providers. Because it cannot
be enable server-side for obvious reasons, a browser-plugin is required.

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
#### Disable Download Bar
The sheer number of downloads is annoying when download bar is enabled. This plugin remedies this:
- https://chrome.google.com/webstore/detail/disable-download-bar/epnnapjdpplekmodajomjojfpeicclep

## OCR Headaches
The quality of OCR remains problematic (with Tesseract 3.05). These tips to improve OCR quality may be useful:
- https://gist.github.com/henrik/1967035

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
