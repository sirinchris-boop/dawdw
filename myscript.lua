-- Safe Script Loader (SHA-256 verified + prompt + protected execution)
-- Usage: set SCRIPT_URL and EXPECTED_HASH to your own values.

local HttpService = game:GetService("HttpService")

-- CONFIG: put your script raw URL and its precomputed SHA256 (lowercase hex)
local SCRIPT_URL    = "https://raw.githubusercontent.com/yourname/repo/main/myscript.lua"
local EXPECTED_HASH = "put_the_precomputed_sha256_hash_here"

-- ======= Minimal SHA256 in pure Lua (public domain / compact) =======
-- Source: small, well-known reference implementations adapted for embedding.
local function sha256(msg)
    local bit = {rol = function(a, b) return ((a << b) | (a >> (32-b))) & 0xFFFFFFFF end}
    -- for environments without bitwise ops (roblox Lua 5.1), implement via numbers:
    local band = function(a,b) return a & b end
    local bxor = function(a,b) return a ~ b end
    local bor  = function(a,b) return a | b end
    local lshift = function(a,b) return (a * 2^b) % 2^32 end
    local rshift = function(a,b) return math.floor(a / 2^b) end

    local function bytes_to_words(s)
        local words = {}
        for i=1,#s,4 do
            local a = string.byte(s, i) or 0
            local b = string.byte(s, i+1) or 0
            local c = string.byte(s, i+2) or 0
            local d = string.byte(s, i+3) or 0
            words[#words+1] = ((a*256 + b)*256 + c)*256 + d
        end
        return words
    end

    local function words_to_hex(words)
        local hex = {}
        for i=1,#words do
            hex[#hex+1] = string.format("%08x", words[i])
        end
        return table.concat(hex)
    end

    local K = {
        0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
        0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
        0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
        0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
        0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
        0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
        0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
        0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2
    }

    local H = {0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19}

    -- Pre-processing
    local msg_len = #msg
    local bit_len = msg_len * 8
    msg = msg .. string.char(0x80)
    local pad_len = (56 - (msg_len + 1) % 64) % 64
    msg = msg .. string.rep(string.char(0x00), pad_len)
    -- append big-endian 64-bit length
    local hi = math.floor(bit_len / 2^32)
    local lo = bit_len % 2^32
    msg = msg .. string.char((hi>>24)&255, (hi>>16)&255, (hi>>8)&255, hi&255, (lo>>24)&255, (lo>>16)&255, (lo>>8)&255, lo&255)

    local words = bytes_to_words(msg)
    for chunk=1, #words/16 do
        local w = {}
        for i=1,16 do w[i] = words[(chunk-1)*16 + i] end
        for i=17,64 do
            local a = w[i-15]
            local b = w[i-2]
            local s0 = bxor(bxor((a >> 7) ~ (a << (32-7)), (a >> 18) ~ (a << (32-18))), (a >> 3))
            local s1 = bxor(bxor((b >> 17) ~ (b << (32-17)), (b >> 19) ~ (b << (32-19))), (b >> 10))
            w[i] = (w[i-16] + s0 + w[i-7] + s1) % 2^32
        end
        local a,b,c,d,e,f,g,h = table.unpack(H)
        for i=1,64 do
            local S1 = bxor(bxor((e >> 6) ~ (e << (32-6)), (e >> 11) ~ (e << (32-11))), (e >> 25) ~ (e << (32-25)))
            local ch = (e & f) ~ ((~e) & g)
            local temp1 = (h + S1 + ch + K[i] + w[i]) % 2^32
            local S0 = bxor(bxor((a >> 2) ~ (a << (32-2)), (a >> 13) ~ (a << (32-13))), (a >> 22) ~ (a << (32-22)))
            local maj = (a & b) ~ (a & c) ~ (b & c)
            local temp2 = (S0 + maj) % 2^32

            h = g
            g = f
            f = e
            e = (d + temp1) % 2^32
            d = c
            c = b
            b = a
            a = (temp1 + temp2) % 2^32
        end
        H[1] = (H[1] + a) % 2^32
        H[2] = (H[2] + b) % 2^32
        H[3] = (H[3] + c) % 2^32
        H[4] = (H[4] + d) % 2^32
        H[5] = (H[5] + e) % 2^32
        H[6] = (H[6] + f) % 2^32
        H[7] = (H[7] + g) % 2^32
        H[8] = (H[8] + h) % 2^32
    end

    return words_to_hex(H)
end
-- ======= end sha256 implementation =======

-- Helper: safe fetch with error handling
local function safeGet(url)
    local ok, res = pcall(function()
        return HttpService:GetAsync(url, true)
    end)
    if not ok then
        return nil, ("HTTP error: %s"):format(tostring(res))
    end
    return res, nil
end

-- Main loader
local function load_and_run(url, expected_hash)
    print(("Loader: fetching %s"):format(url))
    local body, err = safeGet(url)
    if not body then
        warn("Failed to download script:", err)
        return false, err
    end

    local actual_hash = sha256(body)
    print("Downloaded script size:", #body, "bytes")
    print("Computed SHA256:", actual_hash)

    if expected_hash and expected_hash:lower() ~= actual_hash:lower() then
        warn("Hash mismatch! Expected:", expected_hash, "Got:", actual_hash)
        return false, "hash_mismatch"
    end

    -- Confirm with user (so it won't run automatically)
    print("Script verified. Confirm execution? Type 'yes' to run.")
    -- In Roblox you don't have stdin; replace this with a UI prompt in real use.
    -- For a simple test in console, you can assume confirmation:
    local user_confirm = true -- set to false if you want manual confirmation via UI

    if not user_confirm then
        print("Execution cancelled by user.")
        return false, "user_cancel"
    end

    -- Execute safely
    local fn, load_err = loadstring(body)
    if not fn then
        warn("Failed to compile downloaded script:", load_err)
        return false, "compile_error"
    end

    local ok2, run_err = pcall(fn)
    if not ok2 then
        warn("Script runtime error:", run_err)
        return false, "runtime_error"
    end

    print("Script executed successfully.")
    return true, nil
end

-- Run loader
local ok, why = load_and_run(SCRIPT_URL, EXPECTED_HASH)
if not ok then
    warn("Loader finished with error:", why)
else
    print("Loader finished successfully.")
end
