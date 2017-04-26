#!/bin/bash
set -e

EXTRADEFINE="$1"

# Setting LD_LIBRARY_PATH to the current working directory is needed to run
# the tests successfully in linux. Without this, mono can't find libgit when
# the libgit2sharp assembly has been shadow copied. OS X includes the current
# working directory in its library search path, so it works without this value.
export LD_LIBRARY_PATH=.

# Build release for the code generator and the product itself.
export Configuration=release

# Get mono MSBuild to work with .NET SDK projects so we can build
# for both netstandard and net40.
# https://github.com/dotnet/sdk/issues/335#issuecomment-291487227
# https://github.com/OmniSharp/omnisharp-roslyn/blob/ef3d302484fc6c86cfa744d25d9149200f090d31/msbuild.sh
SDK_DIR="/usr/share/dotnet/sdk/1.0.1/"
export MSBuildExtensionsPath=$SDK_DIR
export CscToolExe=$SDK_DIR/Roslyn/RunCsc.sh
export MSBuildSDKsPath=$SDK_DIR/Sdks

dotnet restore
msbuild /v:minimal /m /property:ExtraDefine="$EXTRADEFINE" /fl /flp:verbosity=detailed /t:build,pack

# Test on CoreCLR
dotnet test LibGit2Sharp.Tests/LibGit2Sharp.Tests.csproj -f netcoreapp1.0 --no-build

# Test on mono with the net40 assembly
mono ~/.nuget/packages/xunit.runner.console/2.2.0/tools/xunit.console.exe bin\LibGit2Sharp.Tests\$Configuration\net46\LibGit2Sharp.Tests.dll -noshadow

exit $?
