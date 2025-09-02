local lib = {}

function lib:INFO(_)
end

local JSON = require('rapidjson')
local LCURL = require('lcurl')
local XML = require('lxp.totable')

local DEFAULT_HEADERS = {
    ["Content-Type"] = "application/json",
    ["Accept"] = "application/json",
    ["User-Agent"] = "Lua-cURLv3",
}

--enumerator of applicable methods
local METHOD = {
    GET = "GET",
    POST = "POST",
    PUT = "PUT",
    PATCH = "PATCH",
    DELETE = "DELETE",
    HEAD = "HEAD",
    OPTIONS = "OPTIONS"
}

local CONTENT_TYPE = {
    JSON = "application/json",
    FORM = "application/x-www-form-urlencoded",
    MULTIPART = "multipart/form-data",
    TEXT = "text/plain",
    XML = "application/xml"
}

--do bounds checks of input arguments
local function parseArguments(t)
    if type(t) ~= "table" then
        error("insufficient arguments")
    end
    local ret = {}

    --assert url
    assert(t.url, "URL was not provided.")
    assert(type(t.url) == "string", "URL must be of type string.")
    assert(t.url ~= "", "URL can not be blank.")
    ret.url = t.url

    --check optionals: headers, body, options
    local optionals = {"headers", "body", "options"}
    for _,option in ipairs(optionals) do
        if (t[option] ~= nil) then
            if (option == "body" and type(t[option] == "string")) then
                --skip this assert
            else
                assert(type(t[option]) == "table")
            end
        end
        ret[option] = t[option] or {}
    end

    return ret
end

--main function
local function request(method, t)
    --sanitize inputs
    local args = parseArguments(t)
    local url = args.url
    local request_headers = args["headers"]
    local body = args["body"]
    local options = args["options"]

    --merge headers with defaults
    for k,v in pairs(DEFAULT_HEADERS) do
        if request_headers[k] == nil then
            request_headers[k] = v
        end
    end

    --[[
        ssl_verifypeer refers to if the host has a valid CA SSL cert
    --]]
    local result_body = {}
    local result_headers = {}
    local INIT = {
        url = url,
        ssl_verifypeer = options.ssl_verifypeer or false,
        verbose = options.verbose or 0,
        timeout = options.timeout or 30,
        followlocation = options.followlocation or true,
        maxredirs = options.maxredirs or 5,
        writefunction = function(data)
            if data and type(data) == "string" then
                table.insert(result_body, data)
            end
        end,
        headerfunction = function(header_line)
            if not header_line or type(header_line) ~= "string" then
                return
            end

            --remove whitespaces
            local clean_header = header_line:gsub("%s+$", "")

            if clean_header ~= "" then
                --parse headers
                local header_k, header_v = clean_header:match("^([^:]+):%s*(.*)$")
                if header_k and header_v then
                    -- Normalize header names to lowercase for consistency
                    header_k = header_k:lower():gsub("^%s+", ""):gsub("%s+$", "")
                    header_v = header_v:gsub("^%s+", ""):gsub("%s+$", "")

                    if header_k ~= "" then
                        -- Handle multiple headers with same name (like Set-Cookie)
                        if result_headers[header_k] then
                            if type(result_headers[header_k]) == "table" then
                                table.insert(result_headers[header_k], header_v)
                            else
                                result_headers[header_k] = {result_headers[header_k], header_v}
                            end
                        else
                            result_headers[header_k] = header_v
                        end
                    end
                end
            end
        end
    }
    --Check for TLS
    if url:match("^https://") then
        INIT.ssl_verifyhost = options.ssl_verifyhost or 2 -- Verify hostname matches cert
        if options.cainfo then
            INIT.cainfo = options.cainfo -- Custom CA bundle path
        end
    end

    --init curl request
    local easy = LCURL.easy(INIT)
    if not easy then error("Failed to initialize cURL: "..tostring(error)) end

    --handle request_body
    local request_body
    if options.files or request_headers["Content-Type"] == CONTENT_TYPE.FORM then
        local form = LCURL.form()

        --if options has files, verify has .name and .path
        if options.files then
            for _,file in pairs(options.files) do
                assert(file.name, "file needs property 'name'")
                assert(file.path, "file needs property 'path'")
                file.type = file["type"] or CONTENT_TYPE.TEXT
                form:add_file(file.name, file.path, file.type)
            end
        end

        --if body is populated
        if body and request_headers["Content-Type"] == CONTENT_TYPE.FORM then
            local form_data = {}
            if type(body) == "string" then
                form_data = JSON.decode(body) or {}
                if next(form_data) == nil then
                    --decode by & and =
                    for pair in body:gmatch("[^&]+") do
                        local key, value = pair:match("^([^=]+)=(.*)$")
                        if key then
                            -- URL decode key and value
                            key = key:gsub("+", " "):gsub("%%(%x%x)", function(hex)
                                return string.char(tonumber(hex, 16))
                            end)

                            value = value:gsub("+", " "):gsub("%%(%x%x)", function(hex)
                                return string.char(tonumber(hex, 16))
                            end)

                            form_data[key] = value
                        else
                            -- Handle case where there's no = (just a key)
                            local decoded_key = pair:gsub("+", " "):gsub("%%(%x%x)", function(hex)
                                return string.char(tonumber(hex, 16))
                            end)
                            form_data[decoded_key] = ""
                        end
                    end
                end
            elseif type(body) == "table" then
                if next(body) ~= nil then form_data = body end
            end

            for k,v in pairs(form_data) do
                form:add_content(k, tostring(v))
            end
        end
        request_body = ""
        easy:setopt_httppost(form)
        request_headers["Content-Type"] = nil
    elseif type(body) == "string" then
        request_body = body
    else --default and JSON
        if next(body) ~= nil then
            request_body = JSON.encode(body)
        else
            if type(body) == "table" then
                request_body = ""
            else
                request_body = tostring(body)
            end
        end
    end

    --if username and password, make Basic Auth
    if (request_headers["username"] and request_headers["password"] and options.ignoreBasicAuth == nil) then
        easy:setopt_userpwd(request_headers["username"]..":"..request_headers["password"])
        request_headers["username"] = nil
        request_headers["password"] = nil
    end

    --set request type
    easy:setopt_customrequest(method)
    if method == METHOD.HEAD then easy:setopt_nobody(true) end

    --[[
    proxy options:
    -> proxy is the url of the proxy
    -> setopt_proxyuserpwd sets the header [Proxy-Authorization]: Basic base64
    -> proxyCred and either be "username:password" or {username="",password=""}
    --]]
    if options["proxy"] then --url of proxy
        easy:setopt_proxy(options.proxy)
        if options.proxyCred then
            if type(options.proxyCred) == "string" then
                easy:setopt_proxyuserpwd(options.proxyCred)
            elseif type(options.proxyCred) == "table" then
                easy:setopt_proxyuserpwd(options.proxyCred.username..":"..options.proxyCred.password)
            else
                error("not acceptable proxy options")
            end
        end
    end

    --handle post body
    local body_length = string.len(request_body)
    if (method ~= METHOD.GET and body_length > 0) then
        easy:setopt_postfields(request_body)
        request_headers["Content-Length"] = body_length
    end

    --cast headers as string
    local httpheader = {}
    for k,v in pairs(request_headers) do
        table.insert(httpheader, string.format("%s: %s", k, v))
    end
    easy:setopt_httpheader(httpheader)

    --make the request
    local ok, err = easy:perform()
    if not(ok) then
        return "Error: "..err
    end
    local code = easy:getinfo_response_code()
    local effective_url = easy:getinfo_effective_url()
    easy:close()

    local data
    if result_body ~= nil then
        if type(result_body) == "table" then --usually returns array
            data = table.concat(result_body) --take first element
            if data ~= "" then
                --if result_headers["Content-Encoding"] then end --check if there is encoding?
                local content_type = result_headers["content-type"] or ""
                if content_type:lower():find("application/json") then
                    data = JSON.decode(data) or data
                elseif content_type:lower():find("application/xml") then
                    data = XML.torecord(XML.clean(XML.parse(data))) or data
                end
            else
                --no data
            end
        else
            data = result_body
        end
    end

    --wrap up finish
    return {
        code = code or 0,
        success = code >= 200 and code < 300,
        url = effective_url,
        data = data,
        headers = result_headers
    }
end

function lib:GET(args)
    local ok, res = pcall(request, METHOD.GET, args)
    if not(ok) then return {success=false,"Error: "..res} end
    return res
end

function lib:PUT(args)
    local ok, res = pcall(request, METHOD.PUT, args)
    if not(ok) then return {success=false,"Error: "..res} end
    return res
end

function lib:POST(args)
    local ok, res = pcall(request, METHOD.POST, args)
    if not(ok) then return {success=false,"Error: "..res} end
    return res
end

function lib:PATCH(args)
    local ok, res = pcall(request, METHOD.PATCH, args)
    if not(ok) then return {success=false,"Error: "..res} end
    return res
end

function lib:DELETE(args)
    local ok, res = pcall(request, METHOD.DELETE, args)
    if not(ok) then return {success=false,"Error: "..res} end
    return res
end

function lib:HEAD(args)
    local ok, res = pcall(request, METHOD.HEAD, args)
    if not(ok) then return {success=false,"Error: "..res} end
    return res
end

function lib:OPTIONS(args)
    local ok, res = pcall(request, METHOD.OPTIONS, args)
    if not(ok) then return {success=false,"Error: "..res} end
    return res
end


return lib