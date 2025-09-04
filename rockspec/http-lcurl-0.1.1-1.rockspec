package = "http-lcurl"
version = "0.1.1-1"
source = {
    url = "git://github.com/saspivey98/http-lcurl",
}
description = {
    summary = "HTTP Client to perform HTTP requests using the lcurl library.",
    detailed = [[A Wrapper for lcurl for specifically HTTP requests. 
    This is inspired by Python's Requests library.
    ]],
    license = "MIT",
}
dependencies = {
    "lua >= 5.1",
    "lua-curl >= 0.3.13",
    "rapidjson >= 0.7.1",
    "xml2lua >= 1.6.0"
}
build = {
    type="builtin",
    modules = {
        ['http-lcurl'] = "http-lcurl.lua"
    }
}