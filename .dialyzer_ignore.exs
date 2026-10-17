# Opaque-type false positives that Dialyzer on OTP 28+ reports inside library code;
# drop an entry once `mix dialyzer` passes without it.
[
  # Ecto.Multi.new/0 builds its struct with a MapSet literal (every Ecto.Multi call)
  {"lib/clothing_store/users.ex", :call_without_opaque},
  # Gettext compiles the German and Slovak plural rules into Expo.PluralForms literals
  {"lib/clothing_store_web/gettext.ex", :call_without_opaque}
]
