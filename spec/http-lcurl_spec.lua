-- spec/authentication_spec.lua
describe("Authentication", function()
    local http_client = require('http_client')
    
    describe("Basic Authentication", function()
        it("should handle missing password", function()
            local result = http_client:GET({
                url = "https://example.com",
                headers = {username = "test"}
            })
            -- Should still succeed but not add auth header
            assert.is_true(result.success)
        end)
        
        it("should handle special characters in credentials", function()
            local result = http_client:GET({
                url = "https://example.com",
                headers = {
                    username = "test@domain.com",
                    password = "p@ssw0rd!#$"
                }
            })
            assert.is_true(result.success)
        end)
    end)
    
    describe("Custom Authorization", function()
        it("should preserve custom authorization headers", function()
            local result = http_client:GET({
                url = "https://example.com",
                headers = {
                    Authorization = "Bearer token123"
                }
            })
            assert.is_true(result.success)
        end)
        
        it("should handle API key authentication", function()
            local result = http_client:GET({
                url = "https://example.com",
                headers = {
                    ["X-API-Key"] = "secret-api-key-123"
                }
            })
            assert.is_true(result.success)
        end)
    end)
end)

-- spec/file_upload_spec.lua
describe("File Upload Functionality", function()
    local http_client = require('http_client')
    
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
end)
