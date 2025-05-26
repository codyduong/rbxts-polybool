-- Compiled with roblox-ts v3.0.0
--
-- custom array utility functions for the roblox environment
-- by Cody Duong (@codyduong), https://codyduong.dev
-- todo, this should really be a seperate package
--
-- Project Home: https://github.com/codyduong/rbxts-polybool
-- SPDX-License-Identifier: 0BSD
--
-- rbxts       version: 0.1.1     (https://github.com/codyduong/rbxts-polybool/releases/tag/0.1.1)
-- polybool    version: 2.0.11    (https://github.com/velipso/polybool/releases/tag/v2.0.11)
--
--[[
	*
	 * @param arraysOrValues Arrays or values to concatenate.
	 * @returns A new array containing the concatenated elements.
	 
]]
local ArrayX
local function concat(...)
	local arraysOrValues = { ... }
	local result = {}
	for _, arg in arraysOrValues do
		if ArrayX.isArray(arg) then
			for _1, item in arg do
				table.insert(result, item)
			end
		else
			table.insert(result, arg)
		end
	end
	return result
end
local function isArray(arg)
	-- this check is not very good -@codyduong
	local _arg = arg
	return type(_arg) == "table"
end
--[[
	*
	 * @param arr The array to modify. This array is modified in place.
	 * @param start The index at which to start changing the array.
	 * @param deleteCount? The number of elements to remove.
	 * @param items Elements to insert.
	 * @returns An array containing the removed elements.
	 
]]
local function splice(arr, start, deleteCount, ...)
	local items = { ... }
	if not ArrayX.isArray(arr) then
		error("TypeError: arr must be an array")
	end
	local arrLength = #arr
	local removed = {}
	-- Handle negative start index
	if start < 0 then
		start = math.max(arrLength + start, 0)
	else
		start = math.min(start, arrLength)
	end
	-- Handle deleteCount
	if deleteCount == nil then
		deleteCount = arrLength - start
	else
		deleteCount = math.max(0, math.min(deleteCount, arrLength - start))
	end
	-- 1. Remove elements to be deleted
	do
		local i = start
		local _shouldIncrement = false
		while true do
			if _shouldIncrement then
				i += 1
			else
				_shouldIncrement = true
			end
			if not (i < start + deleteCount) then
				break
			end
			if i < arrLength then
				local _arg0 = arr[i + 1]
				table.insert(removed, _arg0)
			end
		end
	end
	-- 2. Calculate new length and shift elements
	local itemsCount = #items
	local delta = itemsCount - deleteCount
	if delta < 0 then
		-- Shift left (more deleted than inserted)
		local shiftStart = start + deleteCount
		local shiftEnd = arrLength - 1
		local shiftBy = -delta
		do
			local i = shiftStart
			local _shouldIncrement = false
			while true do
				if _shouldIncrement then
					i += 1
				else
					_shouldIncrement = true
				end
				if not (i <= shiftEnd) then
					break
				end
				arr[i - shiftBy + 1] = arr[i + 1]
			end
		end
		-- Remove extra elements from end
		do
			local i = arrLength - 1
			local _shouldIncrement = false
			while true do
				if _shouldIncrement then
					i -= 1
				else
					_shouldIncrement = true
				end
				if not (i >= arrLength + delta) then
					break
				end
				arr[i + 1] = nil
			end
		end
	elseif delta > 0 then
		-- Shift right (more inserted than deleted)
		local shiftStart = arrLength - 1
		local shiftEnd = start + deleteCount
		-- Make space by adding undefined elements
		do
			local i = 0
			local _shouldIncrement = false
			while true do
				if _shouldIncrement then
					i += 1
				else
					_shouldIncrement = true
				end
				if not (i < delta) then
					break
				end
				table.insert(arr, nil)
			end
		end
		-- Shift elements right
		do
			local i = shiftStart
			local _shouldIncrement = false
			while true do
				if _shouldIncrement then
					i -= 1
				else
					_shouldIncrement = true
				end
				if not (i >= shiftEnd) then
					break
				end
				arr[i + delta + 1] = arr[i + 1]
			end
		end
	end
	-- 3. Insert new items
	do
		local i = 0
		local _shouldIncrement = false
		while true do
			if _shouldIncrement then
				i += 1
			else
				_shouldIncrement = true
			end
			if not (i < itemsCount) then
				break
			end
			arr[start + i + 1] = items[i + 1]
		end
	end
	return removed
end
--[[
	*
	 * Simulates JavaScript's Array.prototype.slice
	 * @param arr The array to slice.
	 * @param start The beginning index of the slice.
	 * @param end_ The ending index of the slice (exclusive).
	 * @returns A new array containing the extracted elements.
	 
]]
local function slice(arr, start, end_)
	-- Ensure arr is an array
	if not ArrayX.isArray(arr) then
		error("TypeError: arr must be an array")
	end
	local arrLength = #arr
	local newStart = if start < 0 then math.max(arrLength + start, 0) else math.min(start, arrLength)
	local newEnd
	if end_ == nil then
		newEnd = arrLength
	else
		newEnd = if end_ < 0 then math.max(arrLength + end_, 0) else math.min(end_, arrLength)
	end
	-- Calculate the size needed for the result
	local resultSize = math.max(0, newEnd - newStart)
	local result = {}
	-- Manually truncate by only pushing needed elements
	do
		local i = newStart
		local _shouldIncrement = false
		while true do
			if _shouldIncrement then
				i += 1
			else
				_shouldIncrement = true
			end
			if not (i < newEnd) then
				break
			end
			local _arg0 = arr[i + 1]
			table.insert(result, _arg0)
		end
	end
	-- Ensure the size is correct by removing excess elements
	-- This handles cases where newEnd was before newStart
	while #result > resultSize do
		result[#result] = nil
	end
	return result
end
ArrayX = {
	isArray = isArray,
	concat = concat,
	slice = slice,
	splice = splice,
}
local default = ArrayX
return {
	concat = concat,
	isArray = isArray,
	splice = splice,
	slice = slice,
	default = default,
}
