-- Compiled with roblox-ts v3.0.0
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
--[[
	*
	 * This is a utility type used by polybool, in order to get an alternative representation
	 * or the roblox equivalent Vector2 class, then you will want to use `intoVector2`
	 *
	 * @example
	 * ```
	 * import { intoVector2, Vec2 } from "@rbxts/polybool";
	 *
	 * const vec2: Vec2 = [0.5, 0.5];
	 * const vector2 = intoVector2(vec2);
	 * ```
	 
]]
local function lerp(a, b, t)
	return a + (b - a) * t
end
local function lerpVec2(a, b, t)
	return { lerp(a[1], b[1], t), lerp(a[2], b[2], t) }
end
local function boundingBoxesIntersect(bbox1, bbox2)
	local _binding = bbox1
	local b1min = _binding[1]
	local b1max = _binding[2]
	local _binding_1 = bbox2
	local b2min = _binding_1[1]
	local b2max = _binding_1[2]
	return not (b1min[1] > b2max[1] or b1max[1] < b2min[1] or b1min[2] > b2max[2] or b1max[2] < b2min[2])
end
local Geometry
do
	Geometry = {}
	function Geometry:constructor()
	end
end
local GeometryEpsilon
do
	local super = Geometry
	GeometryEpsilon = setmetatable({}, {
		__tostring = function()
			return "GeometryEpsilon"
		end,
		__index = super,
	})
	GeometryEpsilon.__index = GeometryEpsilon
	function GeometryEpsilon.new(...)
		local self = setmetatable({}, GeometryEpsilon)
		return self:constructor(...) or self
	end
	function GeometryEpsilon:constructor(epsilon)
		if epsilon == nil then
			epsilon = 0.0000000001
		end
		super.constructor(self)
		self.epsilon = epsilon
	end
	function GeometryEpsilon:snap0(v)
		if math.abs(v) < self.epsilon then
			return 0
		end
		return v
	end
	function GeometryEpsilon:snap01(v)
		if math.abs(v) < self.epsilon then
			return 0
		end
		if math.abs(1 - v) < self.epsilon then
			return 1
		end
		return v
	end
	function GeometryEpsilon:isCollinear(p1, p2, p3)
		-- does pt1->pt2->pt3 make a straight line?
		-- essentially this is just checking to see if
		--   slope(pt1->pt2) === slope(pt2->pt3)
		-- if slopes are equal, then they must be collinear, because they share pt2
		local dx1 = p1[1] - p2[1]
		local dy1 = p1[2] - p2[2]
		local dx2 = p2[1] - p3[1]
		local dy2 = p2[2] - p3[2]
		return math.abs(dx1 * dy2 - dx2 * dy1) < self.epsilon
	end
	function GeometryEpsilon:solveCubicNormalized(a, b, c)
		-- based somewhat on gsl_poly_solve_cubic from GNU Scientific Library
		local a3 = a / 3
		local b3 = b / 3
		local Q = a3 * a3 - b3
		local R = a3 * (a3 * a3 - b / 2) + c / 2
		if math.abs(R) < self.epsilon and math.abs(Q) < self.epsilon then
			return { -a3 }
		end
		local F = a3 * (a3 * (4 * a3 * c - b3 * b) - 2 * b * c) + 4 * b3 * b3 * b3 + c * c
		if math.abs(F) < self.epsilon then
			local sqrtQ = math.sqrt(Q)
			return if R > 0 then { -2 * sqrtQ - a / 3, sqrtQ - a / 3 } else { -sqrtQ - a / 3, 2 * sqrtQ - a / 3 }
		end
		local Q3 = Q * Q * Q
		local R2 = R * R
		if R2 < Q3 then
			local ratio = (if R < 0 then -1 else 1) * math.sqrt(R2 / Q3)
			local theta = math.acos(ratio)
			local norm = -2 * math.sqrt(Q)
			local x0 = norm * math.cos(theta / 3) - a3
			local x1 = norm * math.cos((theta + 2 * math.pi) / 3) - a3
			local x2 = norm * math.cos((theta - 2 * math.pi) / 3) - a3
			local _exp = { x0, x1, x2 }
			table.sort(_exp, function(x, y)
				return x <= y
			end)
			return _exp
		else
			local A = (if R < 0 then 1 else -1) * math.pow(math.abs(R) + math.sqrt(R2 - Q3), 1 / 3)
			local B = if math.abs(A) >= self.epsilon then Q / A else 0
			return { A + B - a3 }
		end
	end
	function GeometryEpsilon:solveCubic(a, b, c, d)
		if math.abs(a) < self.epsilon then
			-- quadratic
			if math.abs(b) < self.epsilon then
				-- linear case
				if math.abs(c) < self.epsilon then
					-- horizontal line
					return if math.abs(d) < self.epsilon then { 0 } else {}
				end
				return { -d / c }
			end
			local b2 = 2 * b
			local D = c * c - 4 * b * d
			if math.abs(D) < self.epsilon then
				return { -c / b2 }
			elseif D > 0 then
				D = math.sqrt(D)
				local _exp = { (-c + D) / b2, (-c - D) / b2 }
				table.sort(_exp, function(x, y)
					return x <= y
				end)
				return _exp
			end
			return {}
		end
		return self:solveCubicNormalized(b / a, c / a, d / a)
	end
	function GeometryEpsilon:isEqualVec2(a, b)
		return math.abs(a[1] - b[1]) < self.epsilon and math.abs(a[2] - b[2]) < self.epsilon
	end
	function GeometryEpsilon:compareVec2(a, b)
		-- returns -1 if a is smaller, 1 if b is smaller, 0 if equal
		if math.abs(b[1] - a[1]) < self.epsilon then
			return if math.abs(b[2] - a[2]) < self.epsilon then 0 elseif a[2] < b[2] then -1 else 1
		end
		return if a[1] < b[1] then -1 else 1
	end
end
-- checks if something is array by simply checking if it has a size
local quickarray = function(u)
	local _u = u
	local _condition = type(_u) == "table"
	if _condition then
		local _arg0 = #u
		_condition = type(_arg0) == "number"
	end
	return _condition
end
local function isVector2(u)
	local _u = u
	return typeof(_u) == "Vector2"
end
local function isVec2(u)
	local _condition = quickarray(u) and #u == 2
	if _condition then
		local _arg0 = u[1]
		_condition = type(_arg0) == "number"
		if _condition then
			local _arg0_1 = u[2]
			_condition = type(_arg0_1) == "number"
		end
	end
	return _condition
end
local function isVec6(u)
	local _condition = quickarray(u) and #u == 6
	if _condition then
		local _arg0 = u[1]
		_condition = type(_arg0) == "number"
		if _condition then
			local _arg0_1 = u[2]
			_condition = type(_arg0_1) == "number"
			if _condition then
				local _arg0_2 = u[3]
				_condition = type(_arg0_2) == "number"
				if _condition then
					local _arg0_3 = u[4]
					_condition = type(_arg0_3) == "number"
					if _condition then
						local _arg0_4 = u[5]
						_condition = type(_arg0_4) == "number"
						if _condition then
							local _arg0_5 = u[6]
							_condition = type(_arg0_5) == "number"
						end
					end
				end
			end
		end
	end
	return _condition
end
local function intoVec2(vector2)
	local _arg0 = isVector2(vector2)
	assert(_arg0)
	return { vector2.X, vector2.Y }
end
local function intoVector2(u)
	local _arg0 = isVec2(u) or isVec6(u)
	assert(_arg0)
	if isVec2(u) then
		return Vector2.new(u[1], u[2])
	end
	print(debug.traceback("Polybool: coerced Vec6 as Vec2 in order to convert it to Vec2"))
	return Vector2.new(u[1], u[2])
end
return {
	lerp = lerp,
	lerpVec2 = lerpVec2,
	boundingBoxesIntersect = boundingBoxesIntersect,
	isVector2 = isVector2,
	isVec2 = isVec2,
	isVec6 = isVec6,
	intoVec2 = intoVec2,
	intoVector2 = intoVector2,
	Geometry = Geometry,
	GeometryEpsilon = GeometryEpsilon,
}
