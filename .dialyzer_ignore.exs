# Ecto.Multi.new/0 builds its struct with a MapSet literal, which Dialyzer on OTP 28+
# reports as breaking MapSet's opaque type at every Ecto.Multi call. A false positive
# in Ecto, not in this code; drop the entry once `mix dialyzer` passes without it.
[
  {"lib/clothing_store/users.ex", :call_without_opaque}
]
