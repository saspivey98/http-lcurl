# http-lcurl

[![CI](https://github.com/saspivey98/http-lcurl/actions/workflows/CI.yml/badge.svg)](https://github.com/saspivey98/http-lcurl/actions/workflows/CI.yml)

A friendly HTTP interface for lcurl.

- Wrapper for lua-curl. Documentation can be found [here](https://lua-curl.github.io/lcurl/modules/lcurl.html). 
- All requests are default encoded by JSON and decoded to JSON
- Only supports REST methods (`GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `HEAD`, `OPTIONS`)
- HTTP or HTTPS requests
- Supports requests via proxy
- Supports file uploads on `POST/PUT` requests

## Installation
1. `git clone https://github.com/saspivey98/http-lcurl.git`
2. `luarocks install ./http-lcurl-0.1.1-1.rockspec`

or... (Doesn't work right now, will add to luarocks.org later)

1. `luarocks install http-lcurl`

### Dependencies
- lua >= 5.3
- [lua-curl](https://github.com/Lua-cURL/Lua-cURLv3) >= 0.3.13
- [rapidjson](https://github.com/xpol/lua-rapidjson) >= 0.7.1

*Optional:
- [xml2lua](https://github.com/manoelcampos/xml2lua) >= 1.6.0

## Usage

Import file:
`local HTTP = require('http-lcurl')`

Example `GET` request:
```lua
local HTTP = require('http-lcurl')
local url = "http://localhost:3000/get/"
--by default, username/password headers with be encoded as Basic
local headers = {
    username = "user",
    password = "admin",
    ["Accept-Language"] = "en-US,en;q=0.9"
}
local result = http:GET{url=url, headers=headers}
if result.success then print(result.data) end
```

Example `POST` request:
```lua
local HTTP = require('http-lcurl')
local url = "http://localhost:3000/post/"
local body = {
    data = {
        col1 = "testing",
        col2 = 2
    }
}
local result = http:POST{url=url, body=body}
```

### Options
| option | description | type | Default |
| ------ | ----------- | ---- | ------- |
| ignoreBasicAuth | Skips converting username/password headers to any kind of Auth | bool | `false` |
| digestAuth | Convert username/password headers to digest authentication | bool | `false` |
| NTLMAuth | Convert username/password headers to NTLM authentication | bool | `false` |
| negotiateAuth | Convert username/password headers to Negotiate authentication | bool | `false` |
| files | If doing a POST request, reads this file and `application/x-www-form-urlencoded` header. | table | `nil` |
| ssl_verifypeer | Assert that the host has a valid CA SSL cert | bool | `false` |
| verbose | verbose logging and output from cURL | 0/1 | `0` |
| timeout | time in seconds until cURL request timeout | number | `5` |
| followlocation | follow any HTTP `3XX` responses and retrieve from the new URL specified in the Location header | bool | `true` |
| maxredirs | amount of HTTP `3XX` redirect allowed before returning | number | `5` |
| ssl_verifyhost | Verify hostname matches cert | number | `2` |
| cainfo | Designate a Certificate Authority bundle path | string | `nil` |
| proxy | proxy url address like `proxy.example.com` to send request through | string | `nil` |
| proxyCred | proxy credentials, if applicable | string `(username:password)` or table `{username="",password=""}` | `nil` |

Example request with `options`:
```lua
local HTTP = require('http-lcurl')
local url = "http://localhost:3000/post/"
--by default, username/password headers with be encoded as Basic
local headers = {
    username = "user",
    password = "admin",
    ["Accept-Language"] = "en-US,en;q=0.9"
}
local body = { data = {} }
local options = {
    ignoreBasicAuth = true,
    verbose = 1,
    timeout = 10,
    proxy = "proxy.company.com"
    proxyCred = {
        username = "user",
        password = "pwd"
    }
}
local result = http:POST{url=url, headers=headers, body=body, options=options}
if result.success then print(result.data) end
```

Example with files:
```lua
local HTTP = require('http-lcurl')
local url = "http://localhost:3000/post/"
local filepath = "~/files/file.txt"

local result = HTTP:POST{
    url = url,
    options = {
        files = {
            {
                name="file.txt",
                path=filepath
            }
        }
    }
}
```

## Unit Testing

Using [lua-busted](https://github.com/lunarmodules/busted).

`docker run -d --name httpbin -p 8080:80 kennethreitz/httpbin`

You can run them by running `busted` in the main folder.