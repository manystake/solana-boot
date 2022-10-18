#!/bin/bash

die()
{
	local _ret="${2:-1}"
	test "${_PRINT_HELP:-no}" = yes && print_help >&2
	echo "$1" >&2
	exit "${_ret}"
}


begins_with_short_option()
{
	local first_option all_short_options='crlh'
	first_option="${1:0:1}"
	test "$all_short_options" = "${all_short_options/$first_option/}" && return 1 || return 0
}

# THE DEFAULTS INITIALIZATION - OPTIONALS
_arg_cluster="testnet"
_arg_rpc="https://api.testnet.solana.com"
_arg_ledger="/mnt/solana/ledger"
_arg_log_level="WARN"
_arg_ramdisk_size_gb="200"
_arg_swap_file_size_gb="128"
_arg_secrets_path="/home/solana/.secrets"
_arg_snapshots_path="/mnt/solana/snapshots"
_arg_solana_user="solana"
_arg_solana_version="1.14.5"


print_help()
{
	printf '%s\n' "The general script's help msg"
	printf 'Usage: %s [-c|--cluster <arg>] [-r|--rpc <arg>] [-l|--ledger <arg>] [--log_level <arg>] [--ramdisk_size_gb <arg>] [--swap_file_size_gb <arg>] [--secrets_path <arg>] [--snapshots_path <arg>] [--solana_user <arg>] [--solana_version <arg>] [-h|--help]\n' "$0"
	printf '\t%s\n' "-c, --cluster: Solana cluster (default: 'testnet')"
	printf '\t%s\n' "-r, --rpc: Solana cluster rpc address (default: 'https://api.testnet.solana.com')"
	printf '\t%s\n' "-l, --ledger: Solana client ledger path (default: '/mnt/solana/ledger')"
	printf '\t%s\n' "--log_level: Solana client log level (default: 'WARN')"
	printf '\t%s\n' "--ramdisk_size_gb: Solana client ram disk size (default: '200')"
	printf '\t%s\n' "--swap_file_size_gb: Solana client swap file size (default: '128')"
	printf '\t%s\n' "--secrets_path: Solana client secrets path (default: '/home/solana/.secrets')"
	printf '\t%s\n' "--snapshots_path: Solana client snapshots path (default: '/mnt/solana/snapshots')"
	printf '\t%s\n' "--solana_user: Solana client user (default: 'solana')"
	printf '\t%s\n' "--solana_version: Solana client version (default: '1.14.5')"
	printf '\t%s\n' "-h, --help: Prints help"
}


parse_commandline()
{
	while test $# -gt 0
	do
		_key="$1"
		case "$_key" in
			-c|--cluster)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_cluster="$2"
				shift
				;;
			--cluster=*)
				_arg_cluster="${_key##--cluster=}"
				;;
			-c*)
				_arg_cluster="${_key##-c}"
				;;
			-r|--rpc)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_rpc="$2"
				shift
				;;
			--rpc=*)
				_arg_rpc="${_key##--rpc=}"
				;;
			-r*)
				_arg_rpc="${_key##-r}"
				;;
			-l|--ledger)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_ledger="$2"
				shift
				;;
			--ledger=*)
				_arg_ledger="${_key##--ledger=}"
				;;
			-l*)
				_arg_ledger="${_key##-l}"
				;;
			--log_level)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_log_level="$2"
				shift
				;;
			--log_level=*)
				_arg_log_level="${_key##--log_level=}"
				;;
			--ramdisk_size_gb)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_ramdisk_size_gb="$2"
				shift
				;;
			--ramdisk_size_gb=*)
				_arg_ramdisk_size_gb="${_key##--ramdisk_size_gb=}"
				;;
			--swap_file_size_gb)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_swap_file_size_gb="$2"
				shift
				;;
			--swap_file_size_gb=*)
				_arg_swap_file_size_gb="${_key##--swap_file_size_gb=}"
				;;
			--secrets_path)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_secrets_path="$2"
				shift
				;;
			--secrets_path=*)
				_arg_secrets_path="${_key##--secrets_path=}"
				;;
			--snapshots_path)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_snapshots_path="$2"
				shift
				;;
			--snapshots_path=*)
				_arg_snapshots_path="${_key##--snapshots_path=}"
				;;
			--solana_user)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_solana_user="$2"
				shift
				;;
			--solana_user=*)
				_arg_solana_user="${_key##--solana_user=}"
				;;
			--solana_version)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_solana_version="$2"
				shift
				;;
			--solana_version=*)
				_arg_solana_version="${_key##--solana_version=}"
				;;
			-h|--help)
				print_help
				exit 0
				;;
			-h*)
				print_help
				exit 0
				;;
			*)
				_PRINT_HELP=yes die "FATAL ERROR: Got an unexpected argument '$1'" 1
				;;
		esac
		shift
	done
}

parse_commandline "$@"

install_ansible_collection () {
  timeout 60 ansible-galaxy collection install ansible.posix
  timeout 60 ansible-galaxy collection install community.general
}

init_validator () {

  ansible-playbook \
    --connection=local \
    --inventory ./playbooks/inventory/"$_arg_cluster".yaml \
    --limit localhost  playbooks/bootstrap_validator.yaml \
    --extra-vars "{ \
    'cluster_environment': $_arg_cluster, \
    'cluster_rpc_address': $_arg_rpc, \
    'ledger_path': $_arg_ledger, \
    'log_level': $_arg_log_level, \
    'ramdisk_size_gb': $_arg_ramdisk_size_gb, \
    'swap_file_size_gb': $_arg_swap_file_size_gb, \
    'secrets_path': $_arg_snapshots_path, \
    'solana_user': $_arg_solana_user, \
    'solana_version': $_arg_solana_version, \
    }"

}

init_validator
