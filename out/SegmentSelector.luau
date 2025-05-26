-- Compiled with roblox-ts v3.0.0
local TS = _G[script]
--
-- polybool - Boolean operations on polygons (union, intersection, etc)
-- by Sean Connelly (@velipso), https://sean.fun
-- adapted to roblox by Cody Duong (@codyduong), https://codyduong.dev
--
-- Project Home: https://github.com/codyduong/rbxts-polybool
-- SPDX-License-Identifier: 0BSD
--
-- rbxts       version: 0.1.1     (https://github.com/codyduong/rbxts-polybool/releases/tag/0.1.1)
-- polybool    version: 2.0.11    (https://github.com/velipso/polybool/releases/tag/v2.0.11)
--
-- eslint-disable @typescript-eslint/explicit-function-return-type 
-- eslint-disable @typescript-eslint/strict-boolean-expressions 
local _Intersecter = TS.import(script, script.Parent, "Intersecter")
local SegmentBoolLine = _Intersecter.SegmentBoolLine
local SegmentBoolCurve = _Intersecter.SegmentBoolCurve
--
-- filter a list of segments based on boolean operations
--
-- `select` is reserved
local function selectt(segments, selection, log)
	local result = {}
	for _, seg in segments do
		local index = (if seg.myFill.above then 8 else 0) + (if seg.myFill.below then 4 else 0) + (if seg.otherFill and seg.otherFill.above then 2 else 0) + (if seg.otherFill and seg.otherFill.below then 1 else 0)
		local flags = selection[index + 1]
		local above = (bit32.band(flags, 1)) ~= 0
		local below = (bit32.band(flags, 2)) ~= 0
		if (not seg.closed and flags ~= 0) or (seg.closed and above ~= below) then
			-- copy the segment to the results, while also calculating the fill status
			local fill = {
				above = above,
				below = below,
			}
			if TS.instanceof(seg, SegmentBoolLine) then
				local _segmentBoolLine = SegmentBoolLine.new(seg.data, fill, seg.closed, log)
				table.insert(result, _segmentBoolLine)
			elseif TS.instanceof(seg, SegmentBoolCurve) then
				local _segmentBoolCurve = SegmentBoolCurve.new(seg.data, fill, seg.closed, log)
				table.insert(result, _segmentBoolCurve)
			else
				error("PolyBool: Unknown SegmentBool type in SegmentSelector")
			end
		end
	end
	local _result = log
	if _result ~= nil then
		_result:selected(result)
	end
	return result
end
local SegmentSelector
do
	SegmentSelector = setmetatable({}, {
		__tostring = function()
			return "SegmentSelector"
		end,
	})
	SegmentSelector.__index = SegmentSelector
	function SegmentSelector.new(...)
		local self = setmetatable({}, SegmentSelector)
		return self:constructor(...) or self
	end
	function SegmentSelector:constructor()
	end
	function SegmentSelector:union(segments, log)
		-- primary | secondary
		-- above1 below1 above2 below2    Keep?               Value
		--    0      0      0      0   =>   yes if open         4
		--    0      0      0      1   =>   yes filled below    2
		--    0      0      1      0   =>   yes filled above    1
		--    0      0      1      1   =>   no                  0
		--    0      1      0      0   =>   yes filled below    2
		--    0      1      0      1   =>   yes filled below    2
		--    0      1      1      0   =>   no                  0
		--    0      1      1      1   =>   no                  0
		--    1      0      0      0   =>   yes filled above    1
		--    1      0      0      1   =>   no                  0
		--    1      0      1      0   =>   yes filled above    1
		--    1      0      1      1   =>   no                  0
		--    1      1      0      0   =>   no                  0
		--    1      1      0      1   =>   no                  0
		--    1      1      1      0   =>   no                  0
		--    1      1      1      1   =>   no                  0
		return selectt(segments, { 4, 2, 1, 0, 2, 2, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0 }, log)
	end
	function SegmentSelector:intersect(segments, log)
		-- primary & secondary
		-- above1 below1 above2 below2    Keep?               Value
		--    0      0      0      0   =>   no                  0
		--    0      0      0      1   =>   no                  0
		--    0      0      1      0   =>   no                  0
		--    0      0      1      1   =>   yes if open         4
		--    0      1      0      0   =>   no                  0
		--    0      1      0      1   =>   yes filled below    2
		--    0      1      1      0   =>   no                  0
		--    0      1      1      1   =>   yes filled below    2
		--    1      0      0      0   =>   no                  0
		--    1      0      0      1   =>   no                  0
		--    1      0      1      0   =>   yes filled above    1
		--    1      0      1      1   =>   yes filled above    1
		--    1      1      0      0   =>   yes if open         4
		--    1      1      0      1   =>   yes filled below    2
		--    1      1      1      0   =>   yes filled above    1
		--    1      1      1      1   =>   no                  0
		return selectt(segments, { 0, 0, 0, 4, 0, 2, 0, 2, 0, 0, 1, 1, 4, 2, 1, 0 }, log)
	end
	function SegmentSelector:difference(segments, log)
		-- primary - secondary
		-- above1 below1 above2 below2    Keep?               Value
		--    0      0      0      0   =>   yes if open         4
		--    0      0      0      1   =>   no                  0
		--    0      0      1      0   =>   no                  0
		--    0      0      1      1   =>   no                  0
		--    0      1      0      0   =>   yes filled below    2
		--    0      1      0      1   =>   no                  0
		--    0      1      1      0   =>   yes filled below    2
		--    0      1      1      1   =>   no                  0
		--    1      0      0      0   =>   yes filled above    1
		--    1      0      0      1   =>   yes filled above    1
		--    1      0      1      0   =>   no                  0
		--    1      0      1      1   =>   no                  0
		--    1      1      0      0   =>   no                  0
		--    1      1      0      1   =>   yes filled above    1
		--    1      1      1      0   =>   yes filled below    2
		--    1      1      1      1   =>   no                  0
		return selectt(segments, { 4, 0, 0, 0, 2, 0, 2, 0, 1, 1, 0, 0, 0, 1, 2, 0 }, log)
	end
	function SegmentSelector:differenceRev(segments, log)
		-- secondary - primary
		-- above1 below1 above2 below2    Keep?               Value
		--    0      0      0      0   =>   yes if open         4
		--    0      0      0      1   =>   yes filled below    2
		--    0      0      1      0   =>   yes filled above    1
		--    0      0      1      1   =>   no                  0
		--    0      1      0      0   =>   no                  0
		--    0      1      0      1   =>   no                  0
		--    0      1      1      0   =>   yes filled above    1
		--    0      1      1      1   =>   yes filled above    1
		--    1      0      0      0   =>   no                  0
		--    1      0      0      1   =>   yes filled below    2
		--    1      0      1      0   =>   no                  0
		--    1      0      1      1   =>   yes filled below    2
		--    1      1      0      0   =>   no                  0
		--    1      1      0      1   =>   no                  0
		--    1      1      1      0   =>   no                  0
		--    1      1      1      1   =>   no                  0
		return selectt(segments, { 4, 2, 1, 0, 0, 0, 1, 1, 0, 2, 0, 2, 0, 0, 0, 0 }, log)
	end
	function SegmentSelector:xor(segments, log)
		-- primary ^ secondary
		-- above1 below1 above2 below2    Keep?               Value
		--    0      0      0      0   =>   yes if open         4
		--    0      0      0      1   =>   yes filled below    2
		--    0      0      1      0   =>   yes filled above    1
		--    0      0      1      1   =>   no                  0
		--    0      1      0      0   =>   yes filled below    2
		--    0      1      0      1   =>   no                  0
		--    0      1      1      0   =>   no                  0
		--    0      1      1      1   =>   yes filled above    1
		--    1      0      0      0   =>   yes filled above    1
		--    1      0      0      1   =>   no                  0
		--    1      0      1      0   =>   no                  0
		--    1      0      1      1   =>   yes filled below    2
		--    1      1      0      0   =>   no                  0
		--    1      1      0      1   =>   yes filled above    1
		--    1      1      1      0   =>   yes filled below    2
		--    1      1      1      1   =>   no                  0
		return selectt(segments, { 4, 2, 1, 0, 2, 0, 0, 1, 1, 0, 0, 2, 0, 1, 2, 0 }, log)
	end
end
return {
	SegmentSelector = SegmentSelector,
}
