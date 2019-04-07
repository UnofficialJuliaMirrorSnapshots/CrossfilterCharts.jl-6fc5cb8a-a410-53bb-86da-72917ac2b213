mutable struct Group
	dim::Dimension
	name::String
	reduction::String
end
Base.write(io::IO, group::Group) = print(io, "var ", group.name, " = ", group.dim.name, ".group().", group.reduction, ";")

"""
  reduce_count

A reduction for a Group that is simply reduceCount()
"""
reduce_count(dim::Dimension) = Group(dim, string(dim.name)*"_count", "reduceCount()")

"""
  reduce_sum

A reduction for a Group that sums the values.
"""
reduce_sum(dim::Dimension) = Group(dim, string(dim.name)*"_sum", @sprintf("reduceSum(function(d){ return d.%s; })", dim.name))

"""
  reduce_sum

 A master reduction which sums values from all provided columns and tallies a count.
 Useful for making more complex charts like bubble charts.
"""
function reduce_master(dim::Dimension, columns::Vector{Symbol})
  reduction_str = IOBuffer()
  write(reduction_str, "reduce(function (p, v) {
  ++p.DCCount;
")
  for col in columns
    write(reduction_str, "  p.", col, "_sum += v.", col, ";\n")
  end
  write(reduction_str,"  return p;
},
function (p, v) {
  --p.DCCount;
")
  for col in columns
    write(reduction_str, "  p.", col, "_sum -= v.", col, ";\n")
  end
  write(reduction_str, "  return p;
},
function () {
  return {
    DCCount: 0,
")
  for col in columns
    write(reduction_str, "    ", col, "_sum: 0,\n")
  end
  write(reduction_str, "  };
})")
  # Assign a random number to master reduction so it doesn't get overwritten
  Group(dim, string(dim.name, "_master", rand(0:999)), String(take!(reduction_str)))
end

"""
  infer_group

Infer construction of a group based on the array datatype.
"""
infer_group(arr::AbstractVector{I}, dim::Dimension) where {I<:Integer} = reduce_sum(dim)
infer_group(arr::AbstractVector{F}, dim::Dimension) where {F<:AbstractFloat} = reduce_sum(dim)
infer_group(arr::AbstractVector{S}, dim::Dimension) where {S<:AbstractString} = reduce_count(dim)