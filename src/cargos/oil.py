from cargo import Cargo

cargo = Cargo(
    id="oil",
    type_name="TTD_STR_CARGO_PLURAL_OIL",
    unit_name="TTD_STR_CARGO_SINGULAR_OIL",
    type_abbreviation="TTD_STR_ABBREV_OIL",
    sprite="NEW_CARGO_SPRITE",
    weight="0.9",
    is_freight="1",
    cargo_classes = ["CC_LIQUID_BULK", "CC_NON_POTABLE"],
    cargo_label="OIL_",
    # apart from TOWNGROWTH_PASSENGERS and TOWNGROWTH_MAIL, FIRS does not set any town growth effects; this has the intended effect of disabling food / water requirements for towns in desert and above snowline
    town_growth_effect="TOWNGROWTH_NONE",
    town_growth_multiplier="1.0",
    units_of_cargo="TTD_STR_LITERS",
    items_of_cargo="TTD_STR_QUANTITY_OIL",
    penalty_lowerbound="30",
    single_penalty_length="255",
    price_factor=0,
    capacity_multiplier="1",
    icon_indices=(3, 0),
)
