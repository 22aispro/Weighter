export type WeightClass = {
	Weights: {[string]: number}; 	-- //raw weight
	
	TotalWeight: number; 			-- // sum of all weights
	Normalized: {[any]: number}; 	-- // weights converted to percentages
	Count: number; 					-- // how many items are weighed
	
	AutoNormalize: boolean; 		-- // if true update percentages on every change
	AllowZero: boolean;				-- // allow items with weight of 0
	
	-- // Methods
	AddObject: (self: WeightClass, Object: {Name: string, Weight: number}) -> ();
	RemoveObject: (self: WeightClass, ObjectName: string) -> ();
	Normalize: (self: WeightClass) -> ();
	Roll: (self: WeightClass) -> ();
	RollNormalized: (self: WeightClass) -> ();
}

local Weighter = {}
Weighter.__index = Weighter

-- Creates a weight class
function Weighter.CreateWeightClass(Objects, AutoNormalize, AllowZero): WeightClass
	local WGHT = {}
	for i, v in Objects do
		WGHT[v.Name] = v.Weight
	end
	
	return setmetatable({
		Weights = WGHT or {};
		TotalWeight = 0;
		Normalized = {};
		Count = 0;
		AutoNormalize = AutoNormalize or true;
		AllowZero = AllowZero or false;
	}, Weighter)
end
-- Converts weights to percentages (cached in .Normalized)
function Weighter:Normalize()
	local total = 0
	for i, v in self.Weights do
		total += v
	end
	
	self.TotalWeight = total
	self.Normalized = {}
	
	for item, weight in self.Weights do
		if total > 0 then
			self.Normalized[item] = weight / total
		else
			self.Normalized[item] = 0
		end
	end
	
	return self.Normalized
end

-- Rolls using weights
function Weighter:Roll()
	if self.TotalWeight <= 0 then
		self:Normalize()
	end
	
	local rand = math.random() * self.TotalWeight
	local running = 0
	
	for item, weight in self.Weights do
		running += weight
		
		if rand <= running then
			return item
		end
	end
end

-- Rolls using % instead of actual weights
function Weighter:RollNormalized()
	local rand = math.random()
	local running = 0
	
	for item, chance in self.Normalized do
		running += chance
		
		if rand <= running then
			return item
		end
	end
end

setmetatable(Weighter, {
	__call = function(_, objects)
		return Weighter.CreateWeightClass(objects)
	end,
})

function Weighter.__call(self: WeightClass)
	return self:Roll()
end

function Weighter.__tostring(self: WeightClass)
	local parts = {}
	for name, weight in self.Weights do
		table.insert(parts, name .. "=" .. weight)
	end
	local WeightsStr = table.concat(parts, ", ")
	return string.format("WeightClass(Count=%d, TotalWeight=%d, Weights={%s})",self.Count, self.TotalWeight, WeightsStr)
end

function Weighter.__add(a: WeightClass, b: WeightClass)
	local new = Weighter.CreateWeightClass({}, a.AutoNormalize, a.AllowZero)

	for name, weight in a.Weights do
		new.Weights[name] = weight
	end

	for name, weight in b.Weights do
		new.Weights[name] = weight
	end

	new:Normalize()
	return new
end

function Weighter.__mul(self: WeightClass, factor)
	for name, weight in self.Weights do
		self.Weights[name] = weight * factor
	end
	
	self:Normalize()
	return self
end

function Weighter.__index(self: WeightClass, key)
	if rawget(Weighter, key) then
		return Weighter[key]
	end
	
	return self.Weights[key]
end

return Weighter
