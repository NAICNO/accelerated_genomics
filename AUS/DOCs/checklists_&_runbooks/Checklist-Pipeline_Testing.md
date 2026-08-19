# Germline & Somatic Pipeline Testing Checklist

**GitHub Issue:** <`link`>
**Date started:** <`date`>
**Tester:**
**Environment / profile used:** _(e.g. `fox`, `PARABRICKS_TSD`)_
**Pipeline commit/version:**

---

## 1. Document Sources

- [ ] Input data source(s) recorded
- [ ] Reference genome / index version recorded
- [ ] Any reference truth sets used for validation (e.g. GIAB) recorded
- [ ] Config file(s) used linked (e.g. `configs/PARABRICKS_FOX.conf`)
- [ ] Parabricks / CUDA / container version recorded
- [ ] Hardware used recorded (node, GPU type/count)

---

## 2. Germline Pipeline

### Run (Germline Pipeline)

- [ ] Exact run command recorded (copy-pasteable)
- [ ] `-profile` used noted
- [ ] Run started: _timestamp_
- [ ] Run completed: _timestamp_ (wall-clock duration: ___)
- [ ] Exit status confirmed (0 / success)
- [ ] If `-resume` used: confirmed which tasks actually re-executed vs. were cached (see known resume-cache gotcha — cached ≠ correctly skipped)

### Results Examination (Germline Pipeline)

- [ ] Output directory structure matches expected layout
- [ ] HaplotypeCaller output file extensions correct (plain `.vcf` + `.vcf.idx`, **not** `.vcf.gz` — known Parabricks constraint)
- [ ] VCF opens/validates (e.g. `bcftools stats` or similar)
- [ ] Variant counts look reasonable (not empty, not wildly off)
- [ ] Coverage/QC metrics reviewed
- [ ] Compared against truth set, if available
- [ ] Log files captured/attached as evidence

---

## 3. Somatic Pipeline

### Run (Somatic Pipeline)

- [ ] Exact run command recorded (copy-pasteable)
- [ ] `-profile` used noted
- [ ] Run started: _timestamp_
- [ ] Run completed: _timestamp_ (wall-clock duration: ___)
- [ ] Exit status confirmed (0 / success)
- [ ] If `-resume` used: confirmed which tasks actually re-executed vs. were cached
- [ ] Tumor-only vs tumor-normal mode noted

### Results Examination (Somatic Pipeline)

- [ ] Output directory structure matches expected layout
- [ ] MuTect2/MutectCaller output files present and correctly named (watch for NO_FILE staging collisions — known gotcha, verify unique placeholder names if optional inputs used)
- [ ] VCF opens/validates
- [ ] Variant counts look reasonable
- [ ] Coverage/QC metrics reviewed
- [ ] Compared against truth set, if available
- [ ] Log files captured/attached as evidence

---

## Gaps

### Gaps — Pipeline

- [ ] _e.g. missing step, config issue, resource scaling problem_

### Gaps — Documentation

- [ ] _e.g. unclear docs, missing example command, outdated config reference_

---

## 4. Cross-Pipeline Checks

- [ ] Both pipelines tested on same/comparable input data (if applicable)
- [ ] Runtime and resource usage compared and recorded
- [ ] Any manual workarounds needed during either run documented
- [ ] Known config gotchas re-verified as not reintroduced:
  - [ ] No stray characters in config files (e.g. past `§` bug in `PARABRICKS_FOX.conf`)
  - [ ] No bare `def` vars in `includeConfig`'d files
  - [ ] `publishDir` paths using closures where needed, not plain interpolated GStrings

---

## 5. Summary

- [ ] Overall completion status for both pipelines
- [ ] Consolidated list of identified gaps (pipeline + documentation), each with a suggested owner/next step
- [ ] Follow-up issues filed for any gaps that need separate tracking
