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
-- rbxts       version: 0.1.0     (https://github.com/codyduong/rbxts-polybool/releases/tag/v0.1.0)
-- polybool    version: 2.0.11    (https://github.com/velipso/polybool/releases/tag/v2.0.11)
--
-- eslint-disable @typescript-eslint/explicit-function-return-type 
local _Geometry = TS.import(script, script.Parent, "Geometry")
local lerpVec2 = _Geometry.lerpVec2
local boundingBoxesIntersect = _Geometry.boundingBoxesIntersect
local SegmentTValuesBuilder
do
	SegmentTValuesBuilder = setmetatable({}, {
		__tostring = function()
			return "SegmentTValuesBuilder"
		end,
	})
	SegmentTValuesBuilder.__index = SegmentTValuesBuilder
	function SegmentTValuesBuilder.new(...)
		local self = setmetatable({}, SegmentTValuesBuilder)
		return self:constructor(...) or self
	end
	function SegmentTValuesBuilder:constructor(geo)
		self.tValues = {}
		self.geo = geo
	end
	function SegmentTValuesBuilder:addArray(ts)
		for _, t in ts do
			local _exp = self.tValues
			table.insert(_exp, t)
		end
		return self
	end
	function SegmentTValuesBuilder:add(t)
		t = self.geo:snap01(t)
		-- ignore values outside 0-1 range
		if t < 0 or t > 1 then
			return self
		end
		for _, tv in self.tValues do
			if self.geo:snap0(t - tv) == 0 then
				-- already have this location
				return self
			end
		end
		local _tValues = self.tValues
		local _t = t
		table.insert(_tValues, _t)
		return self
	end
	function SegmentTValuesBuilder:list()
		table.sort(self.tValues, function(a, b)
			return a <= b
		end)
		return self.tValues
	end
end
local SegmentTValuePairsBuilder
do
	SegmentTValuePairsBuilder = setmetatable({}, {
		__tostring = function()
			return "SegmentTValuePairsBuilder"
		end,
	})
	SegmentTValuePairsBuilder.__index = SegmentTValuePairsBuilder
	function SegmentTValuePairsBuilder.new(...)
		local self = setmetatable({}, SegmentTValuePairsBuilder)
		return self:constructor(...) or self
	end
	function SegmentTValuePairsBuilder:constructor(allowOutOfRange, geo)
		self.tValuePairs = {}
		self.allowOutOfRange = allowOutOfRange
		self.geo = geo
	end
	function SegmentTValuePairsBuilder:add(t1, t2)
		t1 = self.geo:snap01(t1)
		t2 = self.geo:snap01(t2)
		-- ignore values outside 0-1 range
		if not self.allowOutOfRange and (t1 < 0 or t1 > 1 or t2 < 0 or t2 > 1) then
			return self
		end
		for _, tv in self.tValuePairs do
			if self.geo:snap0(t1 - tv[1]) == 0 or self.geo:snap0(t2 - tv[2]) == 0 then
				-- already have this location
				return self
			end
		end
		local _tValuePairs = self.tValuePairs
		local _arg0 = { t1, t2 }
		table.insert(_tValuePairs, _arg0)
		return self
	end
	function SegmentTValuePairsBuilder:list()
		table.sort(self.tValuePairs, function(a, b)
			return a[1] <= b[1]
		end)
		return self.tValuePairs
	end
	function SegmentTValuePairsBuilder:done()
		return if #self.tValuePairs <= 0 then nil else {
			kind = "tValuePairs",
			tValuePairs = self:list(),
		}
	end
end
local SegmentBase
do
	SegmentBase = {}
	function SegmentBase:constructor()
	end
end
local SegmentLine
do
	local super = SegmentBase
	SegmentLine = setmetatable({}, {
		__tostring = function()
			return "SegmentLine"
		end,
		__index = super,
	})
	SegmentLine.__index = SegmentLine
	function SegmentLine.new(...)
		local self = setmetatable({}, SegmentLine)
		return self:constructor(...) or self
	end
	function SegmentLine:constructor(p0, p1, geo)
		super.constructor(self)
		self.p0 = p0
		self.p1 = p1
		self.geo = geo
	end
	function SegmentLine:copy()
		return SegmentLine.new(self.p0, self.p1, self.geo)
	end
	function SegmentLine:isEqual(other)
		return self.geo:isEqualVec2(self.p0, other.p0) and self.geo:isEqualVec2(self.p1, other.p1)
	end
	function SegmentLine:start()
		return self.p0
	end
	function SegmentLine:start2()
		return self.p1
	end
	function SegmentLine:end2()
		return self.p0
	end
	SegmentLine["end"] = function(self)
		return self.p1
	end
	function SegmentLine:setStart(p0)
		self.p0 = p0
	end
	function SegmentLine:setEnd(p1)
		self.p1 = p1
	end
	function SegmentLine:point(t)
		local p0 = self.p0
		local p1 = self.p1
		if t == 0 then
			return p0
		elseif t == 1 then
			return p1
		end
		return { p0[1] + (p1[1] - p0[1]) * t, p0[2] + (p1[2] - p0[2]) * t }
	end
	function SegmentLine:split(ts)
		if #ts <= 0 then
			return { self }
		end
		-- ▼ ReadonlyArray.map ▼
		local _newValue = table.create(#ts)
		local _callback = function(t)
			return self:point(t)
		end
		for _k, _v in ts do
			_newValue[_k] = _callback(_v, _k - 1, ts)
		end
		-- ▲ ReadonlyArray.map ▲
		local pts = _newValue
		local _p1 = self.p1
		table.insert(pts, _p1)
		local result = {}
		local last = self.p0
		for _, p in pts do
			local _segmentLine = SegmentLine.new(last, p, self.geo)
			table.insert(result, _segmentLine)
			last = p
		end
		return result
	end
	function SegmentLine:reverse()
		return SegmentLine.new(self.p1, self.p0, self.geo)
	end
	function SegmentLine:boundingBox()
		local p0 = self.p0
		local p1 = self.p1
		return { { math.min(p0[1], p1[1]), math.min(p0[2], p1[2]) }, { math.max(p0[1], p1[1]), math.max(p0[2], p1[2]) } }
	end
	function SegmentLine:pointOn(p)
		return self.geo:isCollinear(p, self.p0, self.p1)
	end
	function SegmentLine:draw(ctx)
		local p0 = self.p0
		local p1 = self.p1
		ctx.moveTo(p0[1], p0[2])
		ctx.lineTo(p1[1], p1[2])
		return ctx
	end
end
local SegmentCurve
do
	local super = SegmentBase
	SegmentCurve = setmetatable({}, {
		__tostring = function()
			return "SegmentCurve"
		end,
		__index = super,
	})
	SegmentCurve.__index = SegmentCurve
	function SegmentCurve.new(...)
		local self = setmetatable({}, SegmentCurve)
		return self:constructor(...) or self
	end
	function SegmentCurve:constructor(p0, p1, p2, p3, geo)
		super.constructor(self)
		self.p0 = p0
		self.p1 = p1
		self.p2 = p2
		self.p3 = p3
		self.geo = geo
	end
	function SegmentCurve:copy()
		return SegmentCurve.new(self.p0, self.p1, self.p2, self.p3, self.geo)
	end
	function SegmentCurve:isEqual(other)
		return self.geo:isEqualVec2(self.p0, other.p0) and self.geo:isEqualVec2(self.p1, other.p1) and self.geo:isEqualVec2(self.p2, other.p2) and self.geo:isEqualVec2(self.p3, other.p3)
	end
	function SegmentCurve:start()
		return self.p0
	end
	function SegmentCurve:start2()
		return self.p1
	end
	function SegmentCurve:end2()
		return self.p2
	end
	SegmentCurve["end"] = function(self)
		return self.p3
	end
	function SegmentCurve:setStart(p0)
		self.p0 = p0
	end
	function SegmentCurve:setEnd(p3)
		self.p3 = p3
	end
	function SegmentCurve:point(t)
		local p0 = self.p0
		local p1 = self.p1
		local p2 = self.p2
		local p3 = self.p3
		if t == 0 then
			return p0
		elseif t == 1 then
			return p3
		end
		local t1t = (1 - t) * (1 - t)
		local tt = t * t
		local t0 = t1t * (1 - t)
		local t1 = 3 * t1t * t
		local t2 = 3 * tt * (1 - t)
		local t3 = tt * t
		return { p0[1] * t0 + p1[1] * t1 + p2[1] * t2 + p3[1] * t3, p0[2] * t0 + p1[2] * t1 + p2[2] * t2 + p3[2] * t3 }
	end
	function SegmentCurve:split(ts)
		if #ts <= 0 then
			return { self }
		end
		local result = {}
		local splitSingle = function(pts, t)
			local _binding = pts
			local p0 = _binding[1]
			local p1 = _binding[2]
			local p2 = _binding[3]
			local p3 = _binding[4]
			local p4 = lerpVec2(p0, p1, t)
			local p5 = lerpVec2(p1, p2, t)
			local p6 = lerpVec2(p2, p3, t)
			local p7 = lerpVec2(p4, p5, t)
			local p8 = lerpVec2(p5, p6, t)
			local p9 = lerpVec2(p7, p8, t)
			local _segmentCurve = SegmentCurve.new(p0, p4, p7, p9, self.geo)
			table.insert(result, _segmentCurve)
			return { p9, p8, p6, p3 }
		end
		local last = { self.p0, self.p1, self.p2, self.p3 }
		local lastT = 0
		for _, t in ts do
			last = splitSingle(last, (t - lastT) / (1 - lastT))
			lastT = t
		end
		local _segmentCurve = SegmentCurve.new(last[1], last[2], last[3], last[4], self.geo)
		table.insert(result, _segmentCurve)
		return result
	end
	function SegmentCurve:reverse()
		return SegmentCurve.new(self.p3, self.p2, self.p1, self.p0, self.geo)
	end
	function SegmentCurve:getCubicCoefficients(axis)
		local p0 = self.p0[axis + 1]
		local p1 = self.p1[axis + 1]
		local p2 = self.p2[axis + 1]
		local p3 = self.p3[axis + 1]
		return { p3 - 3 * p2 + 3 * p1 - p0, 3 * p2 - 6 * p1 + 3 * p0, 3 * p1 - 3 * p0, p0 }
	end
	function SegmentCurve:boundingTValues()
		local result = SegmentTValuesBuilder.new(self.geo)
		local bounds = function(x0, x1, x2, x3)
			local a = 3 * x3 - 9 * x2 + 9 * x1 - 3 * x0
			local b = 6 * x0 - 12 * x1 + 6 * x2
			local c = 3 * x1 - 3 * x0
			if self.geo:snap0(a) == 0 then
				result:add(-c / b)
			else
				local disc = b * b - 4 * a * c
				if disc >= 0 then
					local sq = math.sqrt(disc)
					result:add((-b + sq) / (2 * a))
					result:add((-b - sq) / (2 * a))
				end
			end
			return result
		end
		local p0 = self.p0
		local p1 = self.p1
		local p2 = self.p2
		local p3 = self.p3
		bounds(p0[1], p1[1], p2[1], p3[1])
		bounds(p0[2], p1[2], p2[2], p3[2])
		return result:list()
	end
	function SegmentCurve:inflectionTValues()
		local result = SegmentTValuesBuilder.new(self.geo)
		result:addArray(self:boundingTValues())
		local p0 = self.p0
		local p1 = self.p1
		local p2 = self.p2
		local p3 = self.p3
		local p10x = 3 * (p1[1] - p0[1])
		local p10y = 3 * (p1[2] - p0[2])
		local p21x = 6 * (p2[1] - p1[1])
		local p21y = 6 * (p2[2] - p1[2])
		local p32x = 3 * (p3[1] - p2[1])
		local p32y = 3 * (p3[2] - p2[2])
		local p210x = 6 * (p2[1] - 2 * p1[1] + p0[1])
		local p210y = 6 * (p2[2] - 2 * p1[2] + p0[2])
		local p321x = 6 * (p3[1] - 2 * p2[1] + p1[1])
		local p321y = 6 * (p3[2] - 2 * p2[2] + p1[2])
		local qx = p10x - p21x + p32x
		local qy = p10y - p21y + p32y
		local rx = p21x - 2 * p10x
		local ry = p21y - 2 * p10y
		local sx = p10x
		local sy = p10y
		local ux = p321x - p210x
		local uy = p321y - p210y
		local vx = p210x
		local vy = p210y
		local A = qx * uy - qy * ux
		local B = qx * vy + rx * uy - qy * vx - ry * ux
		local C = rx * vy + sx * uy - ry * vx - sy * ux
		local D = sx * vy - sy * vx
		for _, s in self.geo:solveCubic(A, B, C, D) do
			result:add(s)
		end
		return result:list()
	end
	function SegmentCurve:boundingBox()
		local p0 = self.p0
		local p3 = self.p3
		local min = { math.min(p0[1], p3[1]), math.min(p0[2], p3[2]) }
		local max = { math.max(p0[1], p3[1]), math.max(p0[2], p3[2]) }
		for _, t in self:boundingTValues() do
			local p = self:point(t)
			min[1] = math.min(min[1], p[1])
			min[2] = math.min(min[2], p[2])
			max[1] = math.max(max[1], p[1])
			max[2] = math.max(max[2], p[2])
		end
		return { min, max }
	end
	function SegmentCurve:mapXtoT(x, force)
		if force == nil then
			force = false
		end
		if self.geo:snap0(self.p0[1] - x) == 0 then
			return 0
		end
		if self.geo:snap0(self.p3[1] - x) == 0 then
			return 1
		end
		local p0 = self.p0[1] - x
		local p1 = self.p1[1] - x
		local p2 = self.p2[1] - x
		local p3 = self.p3[1] - x
		local R = { p3 - 3 * p2 + 3 * p1 - p0, 3 * p2 - 6 * p1 + 3 * p0, 3 * p1 - 3 * p0, p0 }
		for _, t in self.geo:solveCubic(R[1], R[2], R[3], R[4]) do
			local ts = self.geo:snap01(t)
			if ts >= 0 and ts <= 1 then
				return t
			end
		end
		-- force a solution if we know there is one...
		if force or (x >= math.min(self.p0[1], self.p3[1]) and x <= math.max(self.p0[1], self.p3[1])) then
			for attempt = 0, 3 do
				-- collapse an R value to 0, this is so wrong!!!
				local ii = -1
				for i = 0, 3 do
					if R[i + 1] ~= 0 and (ii < 0 or math.abs(R[i + 1]) < math.abs(R[ii + 1])) then
						ii = i
					end
				end
				if ii < 0 then
					return 0
				end
				R[ii + 1] = 0
				-- solve again, but with another 0 to help
				for _, t in self.geo:solveCubic(R[1], R[2], R[3], R[4]) do
					local ts = self.geo:snap01(t)
					if ts >= 0 and ts <= 1 then
						return t
					end
				end
			end
		end
		return false
	end
	function SegmentCurve:mapXtoY(x, force)
		if force == nil then
			force = false
		end
		local t = self:mapXtoT(x, force)
		if t == false then
			return false
		end
		return self:point(t)[2]
	end
	function SegmentCurve:pointOn(p)
		if self.geo:isEqualVec2(self.p0, p) or self.geo:isEqualVec2(self.p3, p) then
			return true
		end
		local y = self:mapXtoY(p[1])
		if y == false then
			return false
		end
		return self.geo:snap0(y - p[2]) == 0
	end
	function SegmentCurve:toLine()
		-- note: this won't work for arbitrary curves, because they could loop back on themselves,
		-- but will work fine for curves that have already been split at all inflection points
		local p0 = self.p0
		local p1 = self.p1
		local p2 = self.p2
		local p3 = self.p3
		if (self.geo:snap0(p0[1] - p1[1]) == 0 and self.geo:snap0(p0[1] - p2[1]) == 0 and self.geo:snap0(p0[1] - p3[1]) == 0) or (self.geo:snap0(p0[2] - p1[2]) == 0 and self.geo:snap0(p0[2] - p2[2]) == 0 and self.geo:snap0(p0[2] - p3[2]) == 0) then
			return SegmentLine.new(p0, p3, self.geo)
		end
		return nil
	end
	function SegmentCurve:draw(ctx)
		local p0 = self.p0
		local p1 = self.p1
		local p2 = self.p2
		local p3 = self.p3
		ctx.moveTo(p0[1], p0[2])
		ctx.bezierCurveTo(p1[1], p1[2], p2[1], p2[2], p3[1], p3[2])
		return ctx
	end
end
local function projectPointOntoSegmentLine(p, seg)
	local dx = seg.p1[1] - seg.p0[1]
	local dy = seg.p1[2] - seg.p0[2]
	local px = p[1] - seg.p0[1]
	local py = p[2] - seg.p0[2]
	local dist = dx * dx + dy * dy
	local dot = px * dx + py * dy
	return dot / dist
end
local function segmentLineIntersectSegmentLine(segA, segB, allowOutOfRange)
	local geo = segA.geo
	local a0 = segA.p0
	local a1 = segA.p1
	local b0 = segB.p0
	local b1 = segB.p1
	local adx = a1[1] - a0[1]
	local ady = a1[2] - a0[2]
	local bdx = b1[1] - b0[1]
	local bdy = b1[2] - b0[2]
	local axb = adx * bdy - ady * bdx
	if geo:snap0(axb) == 0 then
		-- lines are coincident or parallel
		if not geo:isCollinear(a0, a1, b0) then
			-- they're not coincident, so they're parallel, with no intersections
			return nil
		end
		-- otherwise, segments are on top of each other somehow (aka coincident)
		local tB0onA = projectPointOntoSegmentLine(segB.p0, segA)
		local tB1onA = projectPointOntoSegmentLine(segB.p1, segA)
		local tAMin = geo:snap01(math.min(tB0onA, tB1onA))
		local tAMax = geo:snap01(math.max(tB0onA, tB1onA))
		if tAMax < 0 or tAMin > 1 then
			return nil
		end
		local tA0onB = projectPointOntoSegmentLine(segA.p0, segB)
		local tA1onB = projectPointOntoSegmentLine(segA.p1, segB)
		local tBMin = geo:snap01(math.min(tA0onB, tA1onB))
		local tBMax = geo:snap01(math.max(tA0onB, tA1onB))
		if tBMax < 0 or tBMin > 1 then
			return nil
		end
		return {
			kind = "tRangePairs",
			tStart = { math.max(0, tAMin), math.max(0, tBMin) },
			tEnd = { math.min(1, tAMax), math.min(1, tBMax) },
		}
	end
	-- otherwise, not coincident, so they intersect somewhere
	local dx = a0[1] - b0[1]
	local dy = a0[2] - b0[2]
	return SegmentTValuePairsBuilder.new(allowOutOfRange, geo):add((bdx * dy - bdy * dx) / axb, (adx * dy - ady * dx) / axb):done()
end
local function segmentLineIntersectSegmentCurve(segA, segB, allowOutOfRange, invert)
	local geo = segA.geo
	local a0 = segA.p0
	local a1 = segA.p1
	local A = a1[2] - a0[2]
	local B = a0[1] - a1[1]
	if geo:snap0(B) == 0 then
		-- vertical line
		local t = segB:mapXtoT(a0[1], false)
		if t == false then
			return nil
		end
		local y = segB:point(t)[2]
		local s = (y - a0[2]) / A
		local result = SegmentTValuePairsBuilder.new(allowOutOfRange, geo)
		if invert then
			result:add(t, s)
		else
			result:add(s, t)
		end
		return result:done()
	end
	local C = A * a0[1] + B * a0[2]
	local bx = segB:getCubicCoefficients(0)
	local by = segB:getCubicCoefficients(1)
	local rA = A * bx[1] + B * by[1]
	local rB = A * bx[2] + B * by[2]
	local rC = A * bx[3] + B * by[3]
	local rD = A * bx[4] + B * by[4] - C
	local roots = geo:solveCubic(rA, rB, rC, rD)
	local result = SegmentTValuePairsBuilder.new(allowOutOfRange, geo)
	if geo:snap0(A) == 0 then
		-- project curve's X component onto line
		for _, t in roots do
			local X = bx[1] * t * t * t + bx[2] * t * t + bx[3] * t + bx[4]
			local s = (a0[1] - X) / B
			if invert then
				result:add(t, s)
			else
				result:add(s, t)
			end
		end
	else
		-- project curve's Y component onto line
		for _, t in roots do
			local Y = by[1] * t * t * t + by[2] * t * t + by[3] * t + by[4]
			local s = (Y - a0[2]) / A
			if invert then
				result:add(t, s)
			else
				result:add(s, t)
			end
		end
	end
	return result:done()
end
local function segmentCurveIntersectSegmentCurve(segA, segB, allowOutOfRange)
	local geo = segA.geo
	-- dummy coincident calculation for now
	-- TODO: implement actual range/equality testing
	if geo:isEqualVec2(segA.p0, segB.p0) then
		if geo:isEqualVec2(segA.p3, segB.p3) then
			if geo:isEqualVec2(segA.p1, segB.p1) and geo:isEqualVec2(segA.p2, segB.p2) then
				return {
					kind = "tRangePairs",
					tStart = { 0, 0 },
					tEnd = { 1, 1 },
				}
			else
				return {
					kind = "tValuePairs",
					tValuePairs = { { 0, 0 }, { 1, 1 } },
				}
			end
		else
			return {
				kind = "tValuePairs",
				tValuePairs = { { 0, 0 } },
			}
		end
	elseif geo:isEqualVec2(segA.p0, segB.p3) then
		return {
			kind = "tValuePairs",
			tValuePairs = { { 0, 1 } },
		}
	elseif geo:isEqualVec2(segA.p3, segB.p0) then
		return {
			kind = "tValuePairs",
			tValuePairs = { { 1, 0 } },
		}
	elseif geo:isEqualVec2(segA.p3, segB.p3) then
		return {
			kind = "tValuePairs",
			tValuePairs = { { 1, 1 } },
		}
	end
	local result = SegmentTValuePairsBuilder.new(allowOutOfRange, geo)
	local checkCurves
	checkCurves = function(c1, t1L, t1R, c2, t2L, t2R)
		local bbox1 = c1:boundingBox()
		local bbox2 = c2:boundingBox()
		if not boundingBoxesIntersect(bbox1, bbox2) then
			return nil
		end
		local t1M = (t1L + t1R) / 2
		local t2M = (t2L + t2R) / 2
		if geo:snap0(t1R - t1L) == 0 and geo:snap0(t2R - t2L) == 0 then
			result:add(t1M, t2M)
			return nil
		end
		local _binding = c1:split({ 0.5 })
		local c1L = _binding[1]
		local c1R = _binding[2]
		local _binding_1 = c2:split({ 0.5 })
		local c2L = _binding_1[1]
		local c2R = _binding_1[2]
		checkCurves(c1L, t1L, t1M, c2L, t2L, t2M)
		checkCurves(c1R, t1M, t1R, c2L, t2L, t2M)
		checkCurves(c1L, t1L, t1M, c2R, t2M, t2R)
		checkCurves(c1R, t1M, t1R, c2R, t2M, t2R)
	end
	checkCurves(segA, 0, 1, segB, 0, 1)
	return result:done()
end
-- return value:
--   undefined               => no intersection
--   SegmentTValuePairs => the segments intersect along a series of points, whose position is
--                         represented by T values pairs [segA_tValue, segB_tValue]
--                         note: a T value pair is returned even if it's just a shared vertex!
--   SegmentTRangePairs => the segments are coincident (on top of each other), and intersect along a
--                         segment, ranged by T values
local function segmentsIntersect(segA, segB, allowOutOfRange)
	if TS.instanceof(segA, SegmentLine) then
		if TS.instanceof(segB, SegmentLine) then
			return segmentLineIntersectSegmentLine(segA, segB, allowOutOfRange)
		elseif TS.instanceof(segB, SegmentCurve) then
			return segmentLineIntersectSegmentCurve(segA, segB, allowOutOfRange, false)
		end
	elseif TS.instanceof(segA, SegmentCurve) then
		if TS.instanceof(segB, SegmentLine) then
			return segmentLineIntersectSegmentCurve(segB, segA, allowOutOfRange, true)
		elseif TS.instanceof(segB, SegmentCurve) then
			return segmentCurveIntersectSegmentCurve(segA, segB, allowOutOfRange)
		end
	end
	error("PolyBool: Unknown segment instance in segmentsIntersect")
end
return {
	projectPointOntoSegmentLine = projectPointOntoSegmentLine,
	segmentLineIntersectSegmentLine = segmentLineIntersectSegmentLine,
	segmentLineIntersectSegmentCurve = segmentLineIntersectSegmentCurve,
	segmentCurveIntersectSegmentCurve = segmentCurveIntersectSegmentCurve,
	segmentsIntersect = segmentsIntersect,
	SegmentTValuesBuilder = SegmentTValuesBuilder,
	SegmentTValuePairsBuilder = SegmentTValuePairsBuilder,
	SegmentBase = SegmentBase,
	SegmentLine = SegmentLine,
	SegmentCurve = SegmentCurve,
}
