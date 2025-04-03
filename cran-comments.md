## R CMD check results

0 errors | 0 warnings | 3 notes

* This is a new release.

* checking DESCRIPTION meta-information ... NOTE
  License components with restrictions not permitted:
    Apache License (>= 2) + file LICENSE
  
  The package uses Apache License 2.0 for code and includes data licensed
  under the ODbL v1.0 and ESA User License. The LICENSE file clearly separates
  and explains these components. We assume that the NOTE regarding "License
  components with restrictions" refers to Apache 2.0 being combined with file
  LICENSE.
  
  In response to CRAN’s suggestion to split the package into three separate
  packages (one for the data-generation code and one each for the datasets
  under ODbL 1.0 and the ESA User License), we believe this would not be
  appropriate or practical. These datasets are integral to the purpose of
  the package and are designed to be used together with the code. Splitting
  them would not only break the usability of the package, but also result
  in standalone data packages that would likely be rejected by CRAN due to
  their licenses not being on the approved list. To address this, we have
  revised the LICENSE file to clarify that the package as a whole is
  licensed under the Apache License 2.0, and that it contains data governed
  by the ODbL v1.0 and ESA User License which are compatible. These data
  licenses are referenced via links and are clearly described as applying
  only to specific datasets, not the package as a whole.

* checking installed package size ... NOTE
    installed size is  5.4Mb
    sub-directories of 1Mb or more:
      data   5.2Mb

  This is a data package that will be rarely updated.
