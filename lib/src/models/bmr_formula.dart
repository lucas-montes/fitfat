/// Which basal-metabolic-rate equation produced a figure.
///
/// Katch-McArdle is only used when the user tracks body fat and has a percentage
/// set — it needs lean mass, not height, age and gender. Mifflin-St Jeor is the
/// default and needs no label, since it is what most people assume is being
/// computed.
enum BmrFormula { mifflinStJeor, katchMcArdle }
