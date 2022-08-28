local record blake3
    record node
        cv: {integer}
        block: {integer}
        counter: integer
        block_len: integer
        flags: integer
    end

    record hasher
        size: integer
    end
    -- Flags
    flag_chunk_start: integer
    flag_chunk_end: integer
    flag_parent: integer
    flag_root: integer
    flag_keyed_hash: integer
    flag_derive_key_context: integer
    flag_derive_key_material: integer

    -- Default nums
    default_key: {integer}
    block_size: integer
    chunk_size: integer

    -- Sum
    sum: function(string): string
end

blake3.flag_chunk_start = 1
blake3.flag_chunk_end = 2
blake3.flag_parent = 4
blake3.flag_root = 8
blake3.flag_keyed_hash = 16
blake3.flag_derive_key_context = 32
blake3.flag_derive_key_material = 64

blake3.default_key = {
	0x6A09E667, 0xBB67AE85, 0x3C6EF372, 0xA54FF53A,
	0x510E527F, 0x9B05688C, 0x1F83D9AB, 0x5BE0CD19,
}
blake3.block_size = 64
blake3.chunk_size = 1024

local iv = blake3.default_key

local function compress_node(n: blake3.node): {integer}
    local function rotate(x:integer, k:integer): integer -- validate go equivalence with bits.RotateLeft32
        local a:integer = 32
        local s:integer = k & (a - 1)
        return x<<s | x>>(a-s)
    end
    local function overflow(num:integer): integer
        if num > 4294967295 then return num - 4294967296 else return num end
    end
    local function g(a:integer, b:integer, c:integer, d:integer, mx:integer, my:integer): integer, integer, integer, integer
        if mx == nil then mx = 0 end
        if my == nil then my = 0 end
        a = overflow(a + b + mx)
        d = overflow(rotate(d ~ a as integer, -16))
        c = overflow(c + d)
        b = overflow(rotate(b ~ c as integer, -12))
        a = overflow(a + b + my)
        d = overflow(rotate(d ~ a as integer, -8))
        c = overflow(c + d)
        b = overflow(rotate(b ~ c, -7))
        return a, b, c, d
    end	

    -- round 1 (also initializes state)
    -- columns
	local s0, s4, s8, s12 = g(n.cv[1], n.cv[5], iv[1] as integer, n.counter, n.block[1], n.block[2])
	local s1, s5, s9, s13 = g(n.cv[2], n.cv[6], iv[2] as integer, overflow(n.counter>>32), n.block[3], n.block[4])
	local s2, s6, s10, s14 = g(n.cv[3], n.cv[7], iv[3] as integer, n.block_len, n.block[5], n.block[6])
	local s3, s7, s11, s15 = g(n.cv[4], n.cv[8], iv[4] as integer, n.flags, n.block[7], n.block[8])
	-- diagonals
	s0, s5, s10, s15 = g(s0, s5, s10, s15, n.block[9], n.block[10])
	s1, s6, s11, s12 = g(s1, s6, s11, s12, n.block[11], n.block[12])
	s2, s7, s8, s13 = g(s2, s7, s8, s13, n.block[13], n.block[14])
	s3, s4, s9, s14 = g(s3, s4, s9, s14, n.block[15], n.block[16])

	-- round 2
	s0, s4, s8, s12 = g(s0, s4, s8, s12, n.block[3], n.block[7])
	s1, s5, s9, s13 = g(s1, s5, s9, s13, n.block[4], n.block[11])
	s2, s6, s10, s14 = g(s2, s6, s10, s14, n.block[8], n.block[1])
	s3, s7, s11, s15 = g(s3, s7, s11, s15, n.block[5], n.block[14])
	s0, s5, s10, s15 = g(s0, s5, s10, s15, n.block[2], n.block[12])
	s1, s6, s11, s12 = g(s1, s6, s11, s12, n.block[13], n.block[6])
	s2, s7, s8, s13 = g(s2, s7, s8, s13, n.block[10], n.block[15])
	s3, s4, s9, s14 = g(s3, s4, s9, s14, n.block[16], n.block[9])

	-- round 3
	s0, s4, s8, s12 = g(s0, s4, s8, s12, n.block[4], n.block[5])
	s1, s5, s9, s13 = g(s1, s5, s9, s13, n.block[11], n.block[13])
	s2, s6, s10, s14 = g(s2, s6, s10, s14, n.block[14], n.block[3])
	s3, s7, s11, s15 = g(s3, s7, s11, s15, n.block[8], n.block[15])
	s0, s5, s10, s15 = g(s0, s5, s10, s15, n.block[7], n.block[6])
	s1, s6, s11, s12 = g(s1, s6, s11, s12, n.block[10], n.block[1])
	s2, s7, s8, s13 = g(s2, s7, s8, s13, n.block[12], n.block[16])
	s3, s4, s9, s14 = g(s3, s4, s9, s14, n.block[9], n.block[2])

	-- round 4
	s0, s4, s8, s12 = g(s0, s4, s8, s12, n.block[11], n.block[8])
	s1, s5, s9, s13 = g(s1, s5, s9, s13, n.block[13], n.block[10])
	s2, s6, s10, s14 = g(s2, s6, s10, s14, n.block[15], n.block[4])
	s3, s7, s11, s15 = g(s3, s7, s11, s15, n.block[14], n.block[16])
	s0, s5, s10, s15 = g(s0, s5, s10, s15, n.block[5], n.block[1])
	s1, s6, s11, s12 = g(s1, s6, s11, s12, n.block[12], n.block[3])
	s2, s7, s8, s13 = g(s2, s7, s8, s13, n.block[6], n.block[9])
	s3, s4, s9, s14 = g(s3, s4, s9, s14, n.block[2], n.block[7])

	-- round 5
	s0, s4, s8, s12 = g(s0, s4, s8, s12, n.block[13], n.block[14])
	s1, s5, s9, s13 = g(s1, s5, s9, s13, n.block[10], n.block[12])
	s2, s6, s10, s14 = g(s2, s6, s10, s14, n.block[16], n.block[11])
	s3, s7, s11, s15 = g(s3, s7, s11, s15, n.block[15], n.block[9])
	s0, s5, s10, s15 = g(s0, s5, s10, s15, n.block[8], n.block[3])
	s1, s6, s11, s12 = g(s1, s6, s11, s12, n.block[6], n.block[4])
	s2, s7, s8, s13 = g(s2, s7, s8, s13, n.block[1], n.block[2])
	s3, s4, s9, s14 = g(s3, s4, s9, s14, n.block[7], n.block[5])

    -- round 6
	s0, s4, s8, s12 = g(s0, s4, s8, s12, n.block[10], n.block[15])
	s1, s5, s9, s13 = g(s1, s5, s9, s13, n.block[12], n.block[6])
	s2, s6, s10, s14 = g(s2, s6, s10, s14, n.block[9], n.block[13])
	s3, s7, s11, s15 = g(s3, s7, s11, s15, n.block[16], n.block[2])
	s0, s5, s10, s15 = g(s0, s5, s10, s15, n.block[14], n.block[4])
	s1, s6, s11, s12 = g(s1, s6, s11, s12, n.block[1], n.block[11])
	s2, s7, s8, s13 = g(s2, s7, s8, s13, n.block[3], n.block[7])
	s3, s4, s9, s14 = g(s3, s4, s9, s14, n.block[5], n.block[8])

	-- round 7
	s0, s4, s8, s12 = g(s0, s4, s8, s12, n.block[12], n.block[16])
	s1, s5, s9, s13 = g(s1, s5, s9, s13, n.block[6], n.block[1])
	s2, s6, s10, s14 = g(s2, s6, s10, s14, n.block[2], n.block[10])
	s3, s7, s11, s15 = g(s3, s7, s11, s15, n.block[9], n.block[7])
	s0, s5, s10, s15 = g(s0, s5, s10, s15, n.block[15], n.block[11])
	s1, s6, s11, s12 = g(s1, s6, s11, s12, n.block[3], n.block[13])
	s2, s7, s8, s13 = g(s2, s7, s8, s13, n.block[4], n.block[5])
	s3, s4, s9, s14 = g(s3, s4, s9, s14, n.block[8], n.block[14])

    local out:{number} = {
		s0 ~ s8 , s1 ~ s9, s2 ~ s10, s3 ~ s11,
		s4 ~ s12, s5 ~ s13, s6 ~ s14, s7 ~ s15,
		s8 ~ n.cv[1], s9 ~ n.cv[2], s10 ~ n.cv[3], s11 ~ n.cv[4],
		s12 ~ n.cv[5], s13 ~ n.cv[6], s14 ~ n.cv[7], s15 ~ n.cv[8],
	}
    return out as {integer}
end


local function four_bytes_to_int(b:{integer}): integer
    return b[1] | b[2]<<8 | b[3]<<16 | b[4]<<24
end

local function bytes_to_int(b: {integer}): {integer}
    local n:{integer} = {}
    local a:integer = 4
    local size = math.ceil(#b / a)
    for idx=0,size do 
        local uint32:{integer} = {}
        for i=1,a do uint32[i] = 0 end
        for i, v in ipairs({table.unpack(b, (idx*a)+1,(idx*a)+a)}) do 
            uint32[i] = v
        end
        n[#n+1] = four_bytes_to_int(uint32) -- 4 * 8bit
    end
    return n
end

local function int_to_bytes(num:integer): {integer}
    local t:{integer} = {}
    for idx=0,3 do
        t[idx+1] = (num >> (idx * 8)) & 0xFF
    end
    return t
end

local function ints_to_bytes(nums:{integer}): {integer}
    local output:{integer} = {}
    for idx=1,#nums do
        local b = int_to_bytes(nums[idx])
        for idx2=1,#b do
            output[#output+1] = b[idx2]
        end
    end
    return output
end

local function hash_block(b: {integer}): {integer}
    local words = bytes_to_int(b)
    local n:blake3.node = {cv = iv, block = words, block_len = #b, counter = 0, flags = blake3.flag_chunk_start | blake3.flag_chunk_end | blake3.flag_root}
    local output_bytes:{integer} = compress_node(n)
    return ints_to_bytes(output_bytes)
end

local function chaining_value(n: blake3.node): {integer}
    return {table.unpack(compress_node(n), 1, 8)}
end

local function compress_chunk(chunk: {integer}, key: {integer}, counter: integer, flags: integer): blake3.node
    local n: blake3.node = {cv = key, counter = counter, block_len = 64, flags = flags | blake3.flag_chunk_start}
    local block: {integer}
    while #chunk > blake3.block_size do
        block = {table.unpack(chunk, 1, blake3.block_size)}
        local new_chunk: {integer} = {}
        new_chunk = {table.unpack(chunk, blake3.block_size+1, #chunk)}
        chunk = new_chunk
        n.block = bytes_to_int(block)
        n.cv = chaining_value(n)
        n.flags = n.flags ~ blake3.flag_chunk_start
    end
    -- pad last block with zeros
    n.block_len = #chunk
    for idx=1,blake3.block_size do if chunk[idx] == nil then chunk[idx] = 0 end end
    block = {table.unpack(chunk, 1, blake3.block_size)}
    n.block = bytes_to_int(block)
    n.flags = n.flags | blake3.flag_chunk_end
    return n
end

function blake3.sum(str: string): string
    local n:blake3.node = {}
    local b:{integer} = {str:byte(1,-1)}
    local output:{integer}
    local output_str:string = ""
    if #str <= blake3.block_size then
        output = hash_block(b)
        for idx = 1, #output do output_str = output_str .. string.format("%x", output[idx]) end
        return output_str
    elseif #str <= blake3.chunk_size then
        n = compress_chunk(b, iv, 0, 0)
        n.flags = n.flags | blake3.flag_root
    else
        print("wowdythere")
    end
    output = ints_to_bytes(compress_node(n))
    for idx = 1, #output do output_str = output_str .. string.format("%x", output[idx]) end
    return output_str
end

--print(blake3.sum("hello world"))
print(blake3.sum("GTCCTGTCGGGTTTCGCCACCTCTGACTTGAGCGTCGATTTTTGTGATGCTCGTCAGGGGGGCGGAGCCT"))
