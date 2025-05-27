-- Compiled with roblox-ts v3.0.0
local TS = _G[script]
local exports = {}
--
-- polybool - Boolean operations on polygons (union, intersection, etc)
-- by Sean Connelly (@velipso), https://sean.fun
-- adapted to roblox by Cody Duong (@codyduong), https://codyduong.dev
--
-- Project Home: https://github.com/codyduong/rbxts-polybool
-- SPDX-License-Identifier: 0BSD
--
-- rbxts       version: 0.1.2     (https://github.com/codyduong/rbxts-polybool/releases/tag/0.1.2)
-- polybool    version: 2.0.11    (https://github.com/velipso/polybool/releases/tag/v2.0.11)
--
-- eslint-disable @typescript-eslint/explicit-function-return-type 
local GeometryEpsilon = TS.import(script, script, "Geometry").GeometryEpsilon
local Shape = TS.import(script, script, "Shape").Shape
local BuildLog = TS.import(script, script, "BuildLog").default
for _k, _v in TS.import(script, script, "Segment") or {} do
	exports[_k] = _v
end
for _k, _v in TS.import(script, script, "Geometry") or {} do
	exports[_k] = _v
end
for _k, _v in TS.import(script, script, "Intersecter") or {} do
	exports[_k] = _v
end
for _k, _v in TS.import(script, script, "SegmentSelector") or {} do
	exports[_k] = _v
end
for _k, _v in TS.import(script, script, "SegmentChainer") or {} do
	exports[_k] = _v
end
for _k, _v in TS.import(script, script, "Shape") or {} do
	exports[_k] = _v
end
for _k, _v in TS.import(script, script, "BuildLog") or {} do
	exports[_k] = _v
end
local PolyBool
do
	PolyBool = setmetatable({}, {
		__tostring = function()
			return "PolyBool"
		end,
	})
	PolyBool.__index = PolyBool
	function PolyBool.new(...)
		local self = setmetatable({}, PolyBool)
		return self:constructor(...) or self
	end
	function PolyBool:constructor(geo, log)
		if geo == nil then
			geo = GeometryEpsilon.new()
		end
		if log == nil then
			log = nil
		end
		self.geo = geo
		self.log = log
	end
	function PolyBool:shape()
		return Shape.new(self.geo, nil, self.log)
	end
	function PolyBool:buildLog(enable)
		self.log = if enable then BuildLog.new() else nil
		local _result = self.log
		if _result ~= nil then
			_result = _result.list
		end
		return _result
	end
	function PolyBool:segments(poly)
		local shape = self:shape()
		shape:beginPath()
		for _, region in poly.regions do
			local lastPoint = region[#region]
			shape:moveTo(lastPoint[#lastPoint - 1], lastPoint[#lastPoint])
			for _1, p in region do
				if #p == 2 then
					shape:lineTo(p[1], p[2])
				elseif #p == 6 then
					shape:bezierCurveTo(p[1], p[2], p[3], p[4], p[5], p[6])
				else
					error("PolyBool: Invalid point in region")
				end
			end
			shape:closePath()
		end
		return {
			shape = shape,
			inverted = poly.inverted,
		}
	end
	function PolyBool:combine(segments1, segments2)
		return {
			shape = segments1.shape:combine(segments2.shape),
			inverted1 = segments1.inverted,
			inverted2 = segments2.inverted,
		}
	end
	function PolyBool:selectUnion(combined)
		return {
			shape = if combined.inverted1 then if combined.inverted2 then combined.shape:intersect() else combined.shape:difference() elseif combined.inverted2 then combined.shape:differenceRev() else combined.shape:union(),
			inverted = combined.inverted1 or combined.inverted2,
		}
	end
	function PolyBool:selectIntersect(combined)
		return {
			shape = if combined.inverted1 then if combined.inverted2 then combined.shape:union() else combined.shape:differenceRev() elseif combined.inverted2 then combined.shape:difference() else combined.shape:intersect(),
			inverted = combined.inverted1 and combined.inverted2,
		}
	end
	function PolyBool:selectDifference(combined)
		return {
			shape = if combined.inverted1 then if combined.inverted2 then combined.shape:differenceRev() else combined.shape:union() elseif combined.inverted2 then combined.shape:intersect() else combined.shape:difference(),
			inverted = combined.inverted1 and not combined.inverted2,
		}
	end
	function PolyBool:selectDifferenceRev(combined)
		return {
			shape = if combined.inverted1 then if combined.inverted2 then combined.shape:difference() else combined.shape:intersect() elseif combined.inverted2 then combined.shape:union() else combined.shape:differenceRev(),
			inverted = not combined.inverted1 and combined.inverted2,
		}
	end
	function PolyBool:selectXor(combined)
		return {
			shape = combined.shape:xor(),
			inverted = combined.inverted1 ~= combined.inverted2,
		}
	end
	function PolyBool:polygon(segments)
		local regions = {}
		local receiver = {
			beginPath = function() end,
			moveTo = function()
				table.insert(regions, {})
			end,
			lineTo = function(x, y)
				local _exp = regions[#regions]
				local _arg0 = { x, y }
				table.insert(_exp, _arg0)
			end,
			bezierCurveTo = function(c1x, c1y, c2x, c2y, x, y)
				local _exp = regions[#regions]
				local _arg0 = { c1x, c1y, c2x, c2y, x, y }
				table.insert(_exp, _arg0)
			end,
			closePath = function() end,
		}
		segments.shape:output(receiver)
		return {
			regions = regions,
			inverted = segments.inverted,
		}
	end
	function PolyBool:union(poly1, poly2)
		local seg1 = self:segments(poly1)
		local seg2 = self:segments(poly2)
		local comb = self:combine(seg1, seg2)
		local seg3 = self:selectUnion(comb)
		return self:polygon(seg3)
	end
	function PolyBool:intersect(poly1, poly2)
		local seg1 = self:segments(poly1)
		local seg2 = self:segments(poly2)
		local comb = self:combine(seg1, seg2)
		local seg3 = self:selectIntersect(comb)
		return self:polygon(seg3)
	end
	function PolyBool:difference(poly1, poly2)
		local seg1 = self:segments(poly1)
		local seg2 = self:segments(poly2)
		local comb = self:combine(seg1, seg2)
		local seg3 = self:selectDifference(comb)
		return self:polygon(seg3)
	end
	function PolyBool:differenceRev(poly1, poly2)
		local seg1 = self:segments(poly1)
		local seg2 = self:segments(poly2)
		local comb = self:combine(seg1, seg2)
		local seg3 = self:selectDifferenceRev(comb)
		return self:polygon(seg3)
	end
	function PolyBool:xor(poly1, poly2)
		local seg1 = self:segments(poly1)
		local seg2 = self:segments(poly2)
		local comb = self:combine(seg1, seg2)
		local seg3 = self:selectXor(comb)
		return self:polygon(seg3)
	end
end
local polybool = PolyBool.new()
local default = polybool
exports.PolyBool = PolyBool
exports.default = default
return exports
