Internal Structure
------------------

RULES
-----
1. To check if $package is available Section [$package all] has to exist. There must not checked for [package $main{host}].

This file will be later a documentation for the internal structure, a short cheatsheet for the internal variable-names.

Variables:
<table>
	<tr>
		<th>Varible: Name & Type</th>
		<th>Description</th>
	</tr>
	<tr>
		<td>@syspkgs</td>
		<td>This array stores all packages, what the package-manager hast to install.</td>
	</tr>
	<tr>
		<td>@pkgs</td>
		<td>This array stores all packages, what condecht has to install.</td>
	</tr>
	<tr>
		<td>$mode</td>
		<td>String stores, which action condecht has to do. For more information, see the getopt-call at the beginning of the script.</td>
	</tr>
	<tr>
		<td>$config_main</td>
		<td>The path of the main Config-file. (standard: /etc/condecht)</td>
	</tr>
	<tr>
		<td>$config_pkg</td>
		<td>The filename, for which file condecht has to search in the path for the database.</td>
	</tr>
	<tr>
		<td>%files</td>
		<td>Hash contains all values of the parameters "file" of all selected packages, which have to be installed/removed. The keys are the destinations of the config-files.</td>
	</tr>
	<tr>
		<td>%main</td>
		<td>All needed values in the main-section of /etc/condecht saved as parameter => value.</td>
	</tr>
</table>
