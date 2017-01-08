abstract Person

"""
```
Donor(id::Int, blood_type::BloodType)
```
"""
type Donor <: Person
    id::Int
    blood_type::BloodType
end

"""
```
Donor(id::Int, dist::BloodTypeDist)
```
"""
Donor(id::Int, dist::BloodTypeDist) = Donor(id, rand(dist))

"""
```
Patient(id::Int, blood_type::BloodType, PRA::Float64)
```
"""
type Patient <: Person
    id::Int
    blood_type::BloodType
    PRA::Float64
end

"""
```
Patient(id::Int, b_dist::BloodTypeDist, t_dist::PRADist)
```
"""
Patient(id::Int, b_dist::BloodTypeDist, t_dist::PRADist) = Patient(id, rand(b_dist), rand(t_dist))


"""
```
are_compatible(donor::Donor, patient::Patient)
```

Returns `true` if `donor` can donate a kidney to `patient`.
"""
function are_compatible(donor::Donor, patient::Patient)
    blood_compatible = if donor.blood_type == O
        true
    elseif donor.blood_type == A
        patient.blood_type in [A, AB]
    elseif donor.blood_type == B
        patient.blood_type in [B, AB]
    elseif donor.blood_type == AB
        patient.blood_type == AB
    end

    return blood_compatible
end

abstract Pair

"""
```
IncompatiblePair(donor::Donor, patient::Patient)
```
"""
type IncompatiblePair <: Pair
    donor::Donor
    patient::Patient

    function IncompatiblePair(donor::Donor, patient::Patient)
        @assert !are_compatible(donor, patient)
        return new(donor, patient)
    end
end

"""
```
IncompatiblePair(donor_id::Int, patient_id::Int, b_dist::BloodTypeDist, t_dist::PRADist)
```
"""
function IncompatiblePair(donor_id::Int, patient_id::Int, b_dist::BloodTypeDist, t_dist::PRADist)
    donor   = Donor(donor_id, b_dist)
    patient = Patient(patient_id, b_dist, t_dist)
    compatible = are_compatible(donor, patient) && rand() > patient.PRA
    while compatible
        donor   = Donor(donor_id, b_dist)
        patient = Patient(patient_id, b_dist, t_dist)
        compatible = are_compatible(donor, patient) && rand() > patient.PRA
    end
    return IncompatiblePair(donor, patient)
end

function Base.show(io::IO, pair::IncompatiblePair)
    donor   = pair.donor
    patient = pair.patient
    print(io, "\n(Donor $(donor.id) = $(donor.blood_type), ")
    print(io, "Patient $(patient.id) = $(patient.blood_type))")
end

"""
```
CompatiblePair(donor::Donor, patient::Patient)
```

Can only be constructed if `are_compatible(donor, patient)`.
"""
type CompatiblePair <: Pair
    donor::Donor
    patient::Patient

    function CompatiblePair(donor::Donor, patient::Patient)
        @assert are_compatible(donor, patient)
        return new(donor, patient)
    end
end

function Base.show(io::IO, pair::CompatiblePair)
    donor   = pair.donor
    patient = pair.patient
    print(io, "\nDonor $(donor.id) = $(donor.blood_type) -> ")
    print(io, "Patient $(patient.id) = $(patient.blood_type)")
end
