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
