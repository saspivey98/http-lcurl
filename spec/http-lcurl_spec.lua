package.path = "../?.lua;" .. package.path
local package_path = [[C:\Users\sspivey\.vscode\extensions\sspivey.lua-inmation-debugger-1.0.2\runtime\win32-x64\lua53]]
package.path = package_path.."/?.lua;" .. package.path
package.cpath = package_path.."/?.dll;" .. package.cpath
require 'busted.runner'()
local http_client = require('http-lcurl')

local url = "http://localhost:8080"
describe("REST Methods", function()
    describe("GET #GET", function()
        it("should handle with no response body", function()
            local res = http_client:GET{url=url.."/status/200", headers={Accept="text/plain"}}
            assert.is_true(res.success)
            assert.is_equal(res.data, "")
        end)
        it("should handle with response body", function()
            local res = http_client:GET{url=url.."/get"}
            assert.is_true(res.success)
            assert.is_not_nil(res.data)
        end)
        it("should handle different content types", function()
            local res1 = http_client:GET{url=url.."/encoding/utf8", headers={Accept="text/html"}}
            assert.is_string(res1.data)
            local res2 = http_client:GET{url=url.."/json", headers={Accept="application/json"}}
            assert.is_table(res2.data)
            local res3 = http_client:GET{url=url.."/robots.txt", headers={Accept="text/plain"}}
            assert.is_string(res3.data)
            local res4 = http_client:GET{url=url.."/xml", headers={Accept="application/xml"}}
            assert.is_table(res4.data)
        end)
        it("should have default headers", function()
            local res = http_client:GET{url=url.."/headers"}
            assert.is_equal(res.data.headers["Accept"], "application/json")
            assert.is_equal(res.data.headers["User-Agent"], "Lua-cURLv3")
            assert.is_equal(res.data.headers["Content-Type"], "application/json")
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
                headers={["Content-Type"] = "application/x-www-form-urlencoded"},
                body="key1=value1&key2=value2"
            }
            assert.is_true(res1.success)
            assert.is_equal(res1.data.form.key1, "value1")
            assert.is_equal(res1.data.form.key2, "value2")
            local res2 = http_client:POST{
                url=url.."/post",
                headers={["Content-Type"] = "application/x-www-form-urlencoded"},
                body={ key1 = "value1", key2 = "value2" }
            }
            assert.is_true(res2.success)
            assert.is_equal(res2.data.form.key1, "value1")
            assert.is_equal(res2.data.form.key2, "value2")
        end)
        it("should send raw/text request body", function()
            local res = http_client:POST{
                url=url.."/post",
                headers={["Content-Type"] = "text/plain"},
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
                headers={["Content-Type"] = "application/x-www-form-urlencoded"},
                body="key1=value1&key2=value2"
            }
            assert.is_true(res1.success)
            assert.is_equal(res1.data.form.key1, "value1")
            assert.is_equal(res1.data.form.key2, "value2")
            local res2 = http_client:PUT{
                url=url.."/put",
                headers={["Content-Type"] = "application/x-www-form-urlencoded"},
                body={ key1 = "value1", key2 = "value2" }
            }
            assert.is_true(res2.success)
            assert.is_equal(res2.data.form.key1, "value1")
            assert.is_equal(res2.data.form.key2, "value2")
        end)
        it("should send raw/text request body", function()
            local res = http_client:PUT{
                url=url.."/put",
                headers={["Content-Type"] = "text/plain"},
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
    describe("PATCH", function()
        it("should send JSON request body", function()
        end)
        it("should send form-encoded request body", function()
        end)
        it("should send raw/text request body", function()
        end)
        it("should handle empty request body", function()
        end)
        it("should set Content-Type header automatically", function()
        end)
        it("should allow custom Content-Type header", function()
        end)
        it("should handle different response status codes", function()
        end)
        it("should handle response body", function()
        end)
        it("should allow custom headers", function()
        end)
        it("should not crash on bad configuration", function()
        end)
    end)
    describe("DELETE", function()
        it("should handle a DELETE request", function()
        end)
        it("should handle DELETE with query parameters", function()
        end)
        it("should handle DELETE with request body", function()
        end)
        it("should handle DELETE with empty request body", function()
        end)
        it("should allow custom headers", function()
        end)
        it("should handle different response status codes", function()
        end)
        it("should handle response body", function()
        end)
        it("should not crash on bad configuration", function()
        end)
    end)
    describe("HEAD", function()
        it("should handle a HEAD request", function()
        end)
        it("should return headers but no body", function()
        end)
        it("should handle query parameters", function()
        end)
    end)
    describe("OPTIONS", function()
        it("should handle an OPTIONS request", function()
        end)  
        it("should return Allow header", function()
        end)
        it("should handle CORS headers", function()
        end)
    end)
end)

describe("Configuration", function()
    describe("Redirects", function()
    end)
    describe("timeouts", function()
    end)
    describe("SSL/TLS", function()
    end)

    describe("Cookies", function()
    end)
end)

describe("Authentication", function()
end)

describe("File Upload Functionality", function()
    before_each(function()
        -- Mock file operations
        _G.original_io_open = io.open
        io.open = function(filename, mode)
            if filename == "/valid/file.txt" then
                return {
                    read = function() return "file content" end,
                    close = function() end
                }
            elseif filename == "/large/file.bin" then
                return {
                    read = function() return string.rep("x", 1024 * 1024) end, -- 1MB
                    close = function() end
                }
            end
            return nil -- File not found
        end
    end)
    
    after_each(function()
        io.open = _G.original_io_open
    end)
    
    describe("Single File Upload", function()
        it("should upload file from filesystem", function()
            local result = http_client:POST({
                url = "https://example.com/upload",
                options = {
                    files = {
                        document = {
                            filepath = "/valid/file.txt",
                            filename = "document.txt",
                            content_type = "text/plain"
                        }
                    }
                }
            })
            assert.is_true(result.success)
        end)
        
        it("should upload file from memory", function()
            local result = http_client:POST({
                url = "https://example.com/upload",
                options = {
                    files = {
                        document = {
                            content = "In-memory file content",
                            filename = "memory.txt",
                            content_type = "text/plain"
                        }
                    }
                }
            })
            assert.is_true(result.success)
        end)
        
        it("should handle missing file", function()
            local result = http_client:POST({
                url = "https://example.com/upload",
                options = {
                    files = {
                        document = {
                            filepath = "/nonexistent/file.txt",
                            filename = "missing.txt"
                        }
                    }
                }
            })
            assert.is_false(result.success)
        end)
        
        it("should require either content or filepath", function()
            local result = http_client:POST({
                url = "https://example.com/upload",
                options = {
                    files = {
                        document = {
                            filename = "incomplete.txt"
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
                url = "https://example.com/upload",
                options = {
                    files = {
                        document1 = {
                            content = "First file content",
                            filename = "file1.txt",
                            content_type = "text/plain"
                        },
                        document2 = {
                            content = "Second file content",
                            filename = "file2.txt",
                            content_type = "text/plain"
                        }
                    }
                }
            })
            assert.is_true(result.success)
        end)
    end)
    describe("Error Handling", function()
    -- Network errors, malformed responses, connection failures
    end)
end)

