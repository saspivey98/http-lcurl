package.path = "../?.lua;" .. package.path

require 'busted.runner'()
package.loaded['http-lcurl'] = nil
local http_client = require('http-lcurl')

local url = "http://localhost:8080"
describe("REST Methods", function()
    describe("GET #GET", function()
        it("should handle with no response body", function()
            local res = http_client:GET{url=url.."/status/200", headers={Accept=http_client.CONTENT_TYPE.TEXT}}
            assert.is_true(res.success)
            assert.is_equal(res.data, "")
        end)
        it("should handle with response body", function()
            local res = http_client:GET{url=url.."/get"}
            assert.is_true(res.success)
            assert.is_not_nil(res.data)
        end)
        it("should handle different content types", function()
            local res1 = http_client:GET{url=url.."/encoding/utf8", headers={Accept=http_client.CONTENT_TYPE.HTML}}
            assert.is_string(res1.data)
            local res2 = http_client:GET{url=url.."/json", headers={Accept=http_client.CONTENT_TYPE.JSON}}
            assert.is_table(res2.data)
            local res3 = http_client:GET{url=url.."/robots.txt", headers={Accept=http_client.CONTENT_TYPE.TEXT}}
            assert.is_string(res3.data)
            local res4 = http_client:GET{url=url.."/xml", headers={Accept=http_client.CONTENT_TYPE.XML}}
            assert.is_table(res4.data)
        end)
        it("should have default headers", function()
            local res = http_client:GET{url=url.."/headers"}
            assert.is_equal(res.data.headers["Accept"], http_client.CONTENT_TYPE.JSON)
            assert.is_equal(res.data.headers["User-Agent"], "Lua-cURLv3")
            assert.is_equal(res.data.headers["Content-Type"], http_client.CONTENT_TYPE.JSON)
        end)
        it("should allow custom headers", function()
            local res = http_client:GET{url=url.."/headers", headers={Test="UnitTest"}}
            assert.is_equal(res.data.headers["Test"], "UnitTest")
        end)
        it("should not crash on a bad configuration", function()
            --no url
            local res1 = http_client:GET{}
            assert.is_false(res1.success)
            --blank url
            local res2 = http_client:GET{url=""}
            assert.is_false(res2.success)
            --assert types
            local res3 = http_client:GET{url={url=url}}
            assert.is_false(res3.success)
            local res4 = http_client:GET{url=url,headers=""}
            assert.is_false(res4.success)
        end)
        it("should properly encode special characters in query parameters", function()
            local v1 = "café"
            local res1 = http_client:GET{url=url.."/get?value="..v1}
            assert.is_equal(res1.data.args.value, v1)
            local v2 = "测试"
            local res2 = http_client:GET{url=url.."/get?value="..v2}
            assert.is_equal(res2.data.args.value, v2)
        end)
    end)
    --[[
    POST, PUT, and PATCH should have identical tests
    --]]
    describe("POST #POST", function()
        it("should handle a POST request", function()
            local res = http_client:POST{url=url.."/post"}
            assert.is_true(res.success)
        end)
        it("should send JSON request body", function()
            local res = http_client:POST{url=url.."/post", body={"test"}}
            assert.is_true(res.success)
            assert.is_equal(res.data.json[1], "test")
        end)
        it("should send form-encoded request body", function()
            local res1 = http_client:POST{
                url=url.."/post",
                headers={["Content-Type"] = http_client.CONTENT_TYPE.FORM},
                body="key1=value1&key2=value2"
            }
            assert.is_true(res1.success)
            assert.is_equal(res1.data.form["key1"], "value1")
            assert.is_equal(res1.data.form["key2"], "value2")
            local res2 = http_client:POST{
                url=url.."/post",
                headers={["Content-Type"] = http_client.CONTENT_TYPE.FORM},
                body={ key1 = "value1", key2 = "value2" }
            }
            assert.is_true(res2.success)
            assert.is_equal(res2.data.form["key1"], "value1")
            assert.is_equal(res2.data.form["key2"], "value2")
        end)
        it("should send raw/text request body", function()
            local res = http_client:POST{
                url=url.."/post",
                headers={["Content-Type"] = http_client.CONTENT_TYPE.TEXT},
                body="text"
            }
            assert.is_true(res.success)
            assert.is_equal(res.data.data, "text")
        end)
        it("should handle empty request body", function()
            local res = http_client:POST{url=url.."/post"}
            assert.is_true(res.success)
        end)
        it("should set Content-Type header automatically", function()
            local res = http_client:POST{ url=url.."/post", body={key="value"} }
            assert.is_true(res.success)
            assert.is_equal(res.data.json.key, "value")
        end)
        it("should handle different response status codes", function()
            local codes = { 200, 400, 401, 403, 404, 500}
            for _,code in ipairs(codes) do
                local res = http_client:POST{url=url.."/status/"..code}
                if code >= 200 and code <= 300 then
                    assert.is_true(res.success)
                else
                    assert.is_false(res.success)
                end
                assert.is_equal(res.code, code)
            end
        end)
        it("should not crash on bad configuration", function()
            --no url
            local res1 = http_client:POST{}
            assert.is_false(res1.success)
            --blank url
            local res2 = http_client:POST{url=""}
            assert.is_false(res2.success)
            --assert types
            local res3 = http_client:POST{url={url=url}}
            assert.is_false(res3.success)
            local res4 = http_client:POST{url=url,headers=""}
            assert.is_false(res4.success)
        end)
    end)
    describe("PUT #PUT", function()
        it("should handle a POST request", function()
            local res = http_client:PUT{url=url.."/put"}
            assert.is_true(res.success)
        end)
        it("should send JSON request body", function()
            local res = http_client:PUT{url=url.."/put", body={"test"}}
            assert.is_true(res.success)
            assert.is_equal(res.data.json[1], "test")
        end)
        it("should send form-encoded request body", function()
            local res1 = http_client:PUT{
                url=url.."/put",
                headers={["Content-Type"] = http_client.CONTENT_TYPE.FORM},
                body="key1=value1&key2=value2"
            }
            assert.is_true(res1.success)
            assert.is_equal(res1.data.form["key1"], "value1")
            assert.is_equal(res1.data.form["key2"], "value2")
            local res2 = http_client:PUT{
                url=url.."/put",
                headers={["Content-Type"] = http_client.CONTENT_TYPE.FORM},
                body={ key1 = "value1", key2 = "value2" }
            }
            assert.is_true(res2.success)
            assert.is_equal(res2.data.form["key1"], "value1")
            assert.is_equal(res2.data.form["key2"], "value2")
        end)
        it("should send raw/text request body", function()
            local res = http_client:PUT{
                url=url.."/put",
                headers={["Content-Type"] = http_client.CONTENT_TYPE.TEXT},
                body="text"
            }
            assert.is_true(res.success)
            assert.is_equal(res.data.data, "text")
        end)
        it("should handle empty request body", function()
            local res = http_client:PUT{url=url.."/put"}
            assert.is_true(res.success)
        end)
        it("should set Content-Type header automatically", function()
            local res = http_client:PUT{ url=url.."/put", body={key="value"} }
            assert.is_true(res.success)
            assert.is_equal(res.data.json.key, "value")
        end)
        it("should handle different response status codes", function()
            local codes = { 200, 400, 401, 403, 404, 500}
            for _,code in ipairs(codes) do
                local res = http_client:PUT{url=url.."/status/"..code}
                if code >= 200 and code <= 300 then
                    assert.is_true(res.success)
                else
                    assert.is_false(res.success)
                end
                assert.is_equal(res.code, code)
            end
        end)
        it("should not crash on bad configuration", function()
            --no url
            local res1 = http_client:PUT{}
            assert.is_false(res1.success)
            --blank url
            local res2 = http_client:PUT{url=""}
            assert.is_false(res2.success)
            --assert types
            local res3 = http_client:PUT{url={url=url}}
            assert.is_false(res3.success)
            local res4 = http_client:PUT{url=url,headers=""}
            assert.is_false(res4.success)
        end)
    end)
    describe("PATCH #PATCH", function()
        it("should handle a PATCH request", function()
            local res = http_client:PATCH{url=url.."/patch"}
            assert.is_true(res.success)
        end)
        it("should send JSON request body", function()
            local res = http_client:PATCH{url=url.."/patch", body={"test"}}
            assert.is_true(res.success)
            assert.is_equal(res.data.json[1], "test")
        end)
        it("should send form-encoded request body", function()
            local res1 = http_client:PATCH{
                url=url.."/patch",
                headers={["Content-Type"] = http_client.CONTENT_TYPE.FORM},
                body="key1=value1&key2=value2"
            }
            assert.is_true(res1.success)
            assert.is_equal(res1.data.form.key1, "value1")
            assert.is_equal(res1.data.form.key2, "value2")
            local res2 = http_client:PATCH{
                url=url.."/patch",
                headers={["Content-Type"] = http_client.CONTENT_TYPE.FORM},
                body={ key1 = "value1", key2 = "value2" }
            }
            assert.is_true(res2.success)
            assert.is_equal(res2.data.form.key1, "value1")
            assert.is_equal(res2.data.form.key2, "value2")
        end)
        it("should send raw/text request body", function()
            local res = http_client:PATCH{
                url=url.."/patch",
                headers={["Content-Type"] = http_client.CONTENT_TYPE.TEXT},
                body="text"
            }
            assert.is_true(res.success)
            assert.is_equal(res.data.data, "text")
        end)
        it("should handle empty request body", function()
            local res = http_client:PATCH{url=url.."/patch"}
            assert.is_true(res.success)
        end)
        it("should set Content-Type header automatically", function()
            local res = http_client:PATCH{ url=url.."/patch", body={key="value"} }
            assert.is_true(res.success)
            assert.is_equal(res.data.json.key, "value")
        end)
        it("should handle different response status codes", function()
            local codes = { 200, 400, 401, 403, 404, 500}
            for _,code in ipairs(codes) do
                local res = http_client:PATCH{url=url.."/status/"..code}
                if code >= 200 and code <= 300 then
                    assert.is_true(res.success)
                else
                    assert.is_false(res.success)
                end
                assert.is_equal(res.code, code)
            end
        end)
        it("should not crash on bad configuration", function()
            --no url
            local res1 = http_client:PATCH{}
            assert.is_false(res1.success)
            --blank url
            local res2 = http_client:PATCH{url=""}
            assert.is_false(res2.success)
            --assert types
            local res3 = http_client:PATCH{url={url=url}}
            assert.is_false(res3.success)
            local res4 = http_client:PATCH{url=url,headers=""}
            assert.is_false(res4.success)
        end)
    end)
    describe("DELETE #DELETE", function()
        local value = "value"
        it("should handle a DELETE request", function()
            local res = http_client:DELETE{url=url.."/delete"}
            assert.is_true(res.success)
        end)
        it("should handle DELETE with query parameters", function()
            local res = http_client:DELETE{url=url.."/delete?key="..value}
            assert.is_true(res.success)
        end)
        it("should handle DELETE with request body", function()
            local res1 = http_client:DELETE{
                url=url.."/delete",
                headers={["Content-Type"] = http_client.CONTENT_TYPE.TEXT},
                body=value
            }
            assert.is_true(res1.success)
            local res2 = http_client:DELETE{
                url=url.."/delete",
                body={
                    key = value
                }
            }
            assert.is_true(res2.success)
        end)
        it("should handle different response status codes", function()
            local codes = { 200, 400, 401, 403, 404, 500}
            for _,code in ipairs(codes) do
                local res = http_client:DELETE{url=url.."/status/"..code}
                if code >= 200 and code <= 300 then
                    assert.is_true(res.success)
                else
                    assert.is_false(res.success)
                end
                assert.is_equal(res.code, code)
            end
        end)
        it("should not crash on bad configuration", function()
            --no url
            local res1 = http_client:DELETE{}
            assert.is_false(res1.success)
            --blank url
            local res2 = http_client:DELETE{url=""}
            assert.is_false(res2.success)
            --assert types
            local res3 = http_client:DELETE{url={url=url}}
            assert.is_false(res3.success)
            local res4 = http_client:DELETE{url=url,headers=""}
            assert.is_false(res4.success)
        end)
    end)
    --HEAD is identical to GET except is must not return a response body
    describe("HEAD", function()
        it("should handle a HEAD request", function()
            local res = http_client:HEAD{url=url.."/get"}
            assert.is_true(res.success)
        end)
        it("should return headers but no body", function()
            local res = http_client:HEAD{url=url.."/encoding/utf8", headers={Accept=http_client.CONTENT_TYPE.HTML}}
            assert.is_true(res.success)
            assert.is_equal(res.data, "")
        end)
    end)
    --how to test...
    describe("OPTIONS #OPTIONS", function()
        it("should handle CORS headers", function()
            local res = http_client:OPTIONS{url=url.."/anything"}
            local allow = res.headers["access-control-allow-methods"]
            for method in allow:gmatch("([^,]+)") do
                local trimmed = method:match("^%s*(.-)%s*$")
                assert.is_true(type(http_client[trimmed]) == "function")
            end
        end)  
        it("should return Allow header", function()
            local res = http_client:OPTIONS{url=url.."/anything"}
            assert.is_not_nil(res.headers.allow)
        end)
    end)
end)

describe("Configuration #CONFIG", function()
    describe("Redirects", function()
        local headers = { accept = http_client.CONTENT_TYPE.HTML }
        it("should follow redirects automatically", function()
            local res = http_client:GET{url=url.."/redirect-to?url=get", headers=headers}
            assert.is_true(res.success)
        end)
        it("should handle absolute redirects", function()
            local res = http_client:GET{url=url.."/absolute-redirect/1", headers=headers}
            assert.is_true(res.success)
        end)
        it("should follow multiple redirects", function()
            local res = http_client:GET{url=url.."/redirect/3", headers=headers}
            assert.is_true(res.success)
        end)
        it("should respect redirect limits", function()
            local options = { maxredirs = 2 }
            local res1 = http_client:GET{url=url.."/redirect/2", headers=headers, options=options}
            assert.is_true(res1.success)
            local res2 = http_client:GET{url=url.."/redirect/3", headers=headers, options=options}
            assert.is_false(res2.success)
        end)
        it("should not follow redirects when disabled", function()
            local options = { followlocation = false }
            local res = http_client:GET{url=url.."/redirect/1", headers=headers, options=options}
            assert.is_false(res.success)
        end)
    end)
    describe("timeouts", function()
        it("should timeout after the default 5 seconds", function()
            local res2 = http_client:GET{url=url.."/delay/6"}
            assert.is_false(res2.success)
            local res3 = http_client:GET{url=url.."/delay/5"}
            assert.is_false(res3.success)
        end)
        it("should not timeout if the timeout period has been met", function()
            local res2 = http_client:GET{url=url.."/delay/3"}
            assert.is_true(res2.success)
        end)
        it("should have customizable timeout period", function()
            local options = { timeout = 3 }
            local res1 = http_client:GET{url=url.."/delay/2", options=options}
            assert.is_true(res1.success)
            local res2 = http_client:GET{url=url.."/delay/4", options=options}
            assert.is_false(res2.success)
        end)
    end)
    describe("SSL/TLS", function()
        it("should connect over HTTPS successfully", function()
        end)
        it("should fail on HTTP when HTTPS is required", function()
        end)
        it("should handle verify peer certificate options", function() --ssl_verifypeer
        end)
        it("should handle verify hostname options", function() --ssl_verifyhost
        end)
        it("should handle system CA options", function() --cainfo
        end)
    end)

    describe("Cookies", function()
        it("should set cookies from server response", function()
        end)
        it("should send cookies in request", function()
        end)
        it("should maintain cookies across requests", function()
        end)
    end)

    describe("Authentication", function()
        local headers = { username = "username", password = "password" }
        it("should encode username / password as a Basic Auth token", function()
            local res = http_client:GET{url=url.."/get", headers=headers}
            assert.is_true(res.success)
            assert.is_not_nil(res.data.headers.Authorization)
            assert.is_nil(res.data.headers.Username)
            assert.is_nil(res.data.headers.Password)
        end)
        it("should allow the option to not encode username/password as Basic Auth Token", function()
            local options = { ignoreBasicAuth = true }
            local res = http_client:GET{url=url.."/get", headers=headers, options=options}
            assert.is_true(res.success)
            assert.is_nil(res.data.headers.Authorization)
            assert.is_not_nil(res.data.headers.Username)
            assert.is_not_nil(res.data.headers.Password)
        end)
        it("should support digest authentication", function()
            --digest sends auth request first before sending anything else.
            local options = { digestAuth = true }
            local res = http_client:GET{url=url.."/get", headers=headers, options=options}
            assert.is_true(res.success)
            assert.is_nil(res.data.headers.Authorization)
            assert.is_nil(res.data.headers.Username)
            assert.is_nil(res.data.headers.Passwords)
        end)
        it("should support NTLM authentication", function()
            local options = { NTLMAuth = true }
            local res = http_client:GET{url=url.."/get", headers=headers, options=options}
            assert.is_true(res.success)
            assert.is_not_nil(res.data.headers.Authorization)
            assert.is_not_nil(string.find(res.data.headers.Authorization, "NTLM"))
        end)
        it("should support Negotiate authentication", function()
            local options = { negotiateAuth = true }
            local res = http_client:GET{url=url.."/get", headers=headers, options=options}
            assert.is_true(res.success)
            assert.is_not_nil(res.data.headers.Authorization)
            assert.is_not_nil(string.find(res.data.headers.Authorization, "Negotiate"))
        end)
    end)
end)

describe("File Upload Functionality #UPLOAD", function()
    local handle = io.popen(package.config:sub(1,1) == '\\' and "cd" or "pwd")
    local cwd = handle:read("*l")
    handle:close()

    local file1 = cwd.."/spec/file1.txt"
    local file2 = cwd.."/spec/file2.txt"

    describe("Single File Upload", function()
        it("should upload file from filesystem", function()
            local result = http_client:POST({
                url = url.."/post",
                options = {
                    files = {
                        {
                            name="file1.txt",
                            path=file1
                        }
                    }
                }
            })
            assert.is_true(result.success)
            assert.is_not_nil(result.data.files)
        end)

        it("should handle missing file", function()
            local result = http_client:POST({
                url = url.."/post",
                options = {
                    files = {
                        {
                            name="file_bad.txt",
                            path=cwd
                        }
                    }
                }
            })
            assert.is_false(result.success)
        end)
    end)
    
    describe("Multiple File Upload", function()
        it("should upload multiple files", function()
                        local result = http_client:POST({
                url = url.."/post",
                options = {
                    files = {
                        {
                            name="file1.txt",
                            path=file1
                        },
                        {
                            name="file2.txt",
                            path=file2
                        }
                    }
                }
            })
            assert.is_true(result.success)
            assert.is_not_nil(result.data.files)
        end)
    end)
    describe("Error Handling", function()
    -- Network errors, malformed responses, connection failures
    end)
end)

