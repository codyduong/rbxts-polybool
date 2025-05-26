-- Compiled with roblox-ts v3.0.0
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
local BuildLog
do
	BuildLog = setmetatable({}, {
		__tostring = function()
			return "BuildLog"
		end,
	})
	BuildLog.__index = BuildLog
	function BuildLog.new(...)
		local self = setmetatable({}, BuildLog)
		return self:constructor(...) or self
	end
	function BuildLog:constructor()
		self.list = {}
		self.nextSegmentId = 0
		self.curVert = nil
	end
	function BuildLog:push(type_, data)
		local _list = self.list
		local _arg0 = {
			type = type_,
			data = data,
		}
		table.insert(_list, _arg0)
	end
	function BuildLog:info(msg, data)
		self:push("info", {
			msg = msg,
			data = data,
		})
	end
	function BuildLog:segmentId()
		local _original = self.nextSegmentId
		self.nextSegmentId += 1
		return _original
	end
	function BuildLog:checkIntersection(seg1, seg2)
		self:push("check", {
			seg1 = seg1,
			seg2 = seg2,
		})
	end
	function BuildLog:segmentDivide(seg, p)
		self:push("div_seg", {
			seg = seg,
			p = p,
		})
	end
	function BuildLog:segmentChop(seg)
		self:push("chop", {
			seg = seg,
		})
	end
	function BuildLog:statusRemove(seg)
		self:push("pop_seg", {
			seg = seg,
		})
	end
	function BuildLog:segmentUpdate(seg)
		self:push("seg_update", {
			seg = seg,
		})
	end
	function BuildLog:segmentNew(seg, primary)
		self:push("new_seg", {
			seg = seg,
			primary = primary,
		})
	end
	function BuildLog:tempStatus(seg, above, below)
		self:push("temp_status", {
			seg = seg,
			above = above,
			below = below,
		})
	end
	function BuildLog:rewind(seg)
		self:push("rewind", {
			seg = seg,
		})
	end
	function BuildLog:status(seg, above, below)
		self:push("status", {
			seg = seg,
			above = above,
			below = below,
		})
	end
	function BuildLog:vert(x)
		if x ~= self.curVert then
			self:push("vert", {
				x = x,
			})
			self.curVert = x
		end
	end
	function BuildLog:selected(segs)
		self:push("selected", {
			segs = segs,
		})
	end
	function BuildLog:chainStart(sf, closed)
		self:push("chain_start", {
			sf = sf,
			closed = closed,
		})
	end
	function BuildLog:chainNew(sf, closed)
		self:push("chain_new", {
			sf = sf,
			closed = closed,
		})
	end
	function BuildLog:chainMatch(index, closed)
		self:push("chain_match", {
			index = index,
			closed = closed,
		})
	end
	function BuildLog:chainClose(index, closed)
		self:push("chain_close", {
			index = index,
			closed = closed,
		})
	end
	function BuildLog:chainAddHead(index, sf, closed)
		self:push("chain_add_head", {
			index = index,
			sf = sf,
			closed = closed,
		})
	end
	function BuildLog:chainAddTail(index, sf, closed)
		self:push("chain_add_tail", {
			index = index,
			sf = sf,
			closed = closed,
		})
	end
	function BuildLog:chainSimplifyHead(index, sf, closed)
		self:push("chain_simp_head", {
			index = index,
			sf = sf,
			closed = closed,
		})
	end
	function BuildLog:chainSimplifyTail(index, sf, closed)
		self:push("chain_simp_tail", {
			index = index,
			sf = sf,
			closed = closed,
		})
	end
	function BuildLog:chainSimplifyClose(index, sf, closed)
		self:push("chain_simp_close", {
			index = index,
			sf = sf,
			closed = closed,
		})
	end
	function BuildLog:chainSimplifyJoin(index1, index2, sf, closed)
		self:push("chain_simp_join", {
			index1 = index1,
			index2 = index2,
			sf = sf,
			closed = closed,
		})
	end
	function BuildLog:chainConnect(index1, index2, closed)
		self:push("chain_con", {
			index1 = index1,
			index2 = index2,
			closed = closed,
		})
	end
	function BuildLog:chainReverse(index, closed)
		self:push("chain_rev", {
			index = index,
			closed = closed,
		})
	end
	function BuildLog:chainJoin(index1, index2, closed)
		self:push("chain_join", {
			index1 = index1,
			index2 = index2,
			closed = closed,
		})
	end
	function BuildLog:done()
		self:push("done", nil)
	end
end
return {
	default = BuildLog,
}
