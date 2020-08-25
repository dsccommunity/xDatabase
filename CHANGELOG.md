# Change log for xDatabase

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Updated to a new CI/CD pipeline ([issue #47](https://github.com/dsccommunity/xDatabase/issues/47)).
- Adds support for SQL Server 2019,
- Add support for 64bit DAC and SMO ([issue #46](https://github.com/dsccommunity/xDatabase/issues/46)).

## [1.9.0.0] - 2018-09-05

- xDatabase Test-TargetResource will now check DacPacVersion if DacPacPath
  parameter and DB exist. If the DacPacApplicationVersion is supplied and
  matches the deployed version we will return $true ([issue #41](https://github.com/dsccommunity/xDatabase/issues/41)).

## [1.8.0.0] - 2018-06-13

- Added support for SQL Server 2017
- xDBPackage now uses the shared function to identify the paths for the
  different SQL server versions

## [1.7.0.0] - 2018-02-07

- Added support SQL Server 2016

## [1.6.0.0] - 2017-04-19

- Moved internal functions to a common helper module

## [1.5.0.0] - 2016-12-14

- Converted appveyor.yml to install Pester from PSGallery instead of from
  Chocolatey.
- Added logging for when dac deploy fails

## [1.4.0.0] - 2015-10-22

- Error output improvements

## [1.3.0.0] - 2015-09-11

- Fixed mandatory attributes in schema
- Removed parameter DefaultDatabaseName
- Aligned \*.schema.mof with \*.psm1 files

## [1.2.0.0] - 2015-05-01

- Improve support for Credentials.

## [1.1.0.0] - 2015-04-23

- Minor bug fixes

## [1.0.0.0] - 2015-04-15

- Initial release with the following resources
  - xDatabase
  - xDBPackage
