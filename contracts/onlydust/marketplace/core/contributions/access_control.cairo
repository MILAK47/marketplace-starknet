%lang starknet

from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.bool import TRUE, FALSE

from openzeppelin.access.accesscontrol import AccessControl

#
# Enums
#
struct Role:
    # Keep ADMIN role first of this list as 0 is the default admin value to manage roles in AccessControl library
    member ADMIN : felt  # can assign/revoke roles
    member _UNUSED: felt
    member LEAD_CONTRIBUTOR : felt # can add interact with contributions on its project
end

#
# Storage
#
@storage_var
func has_role_by_project_and_account_(role : felt, project: felt, account: felt) -> (has_role: felt):
end

#
# Functions
#
namespace access_control:
    func initialize{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        admin : felt
    ):
        AccessControl.initializer()
        AccessControl._grant_role(Role.ADMIN, admin)
        return ()
    end

    # Grant the ADMIN role to a given address
    func grant_admin_role{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        address : felt
    ):
        AccessControl.grant_role(Role.ADMIN, address)
        return ()
    end

    # Revoke the ADMIN role from a given address
    func revoke_admin_role{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        address : felt
    ):
        with_attr error_message("Contributions: Cannot self renounce to ADMIN role"):
            internal.assert_not_caller(address)
        end
        AccessControl.revoke_role(Role.ADMIN, address)
        return ()
    end

    func only_admin{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
        with_attr error_message("Contributions: ADMIN role required"):
            AccessControl.assert_only_role(Role.ADMIN)
        end

        return ()
    end

    func grant_lead_contributor_role_for_project{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        project_id : felt, lead_contributor_account: felt):
        only_admin()
        has_role_by_project_and_account_.write(Role.LEAD_CONTRIBUTOR, project_id, lead_contributor_account, TRUE)
        return ()
    end

    func revoke_lead_contributor_role_for_project{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        project_id : felt, lead_contributor_account: felt):
        only_admin()
        has_role_by_project_and_account_.write(Role.LEAD_CONTRIBUTOR, project_id, lead_contributor_account, FALSE)
        return ()
    end

    func only_lead_contributor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        project_id : felt):
        alloc_locals

        let (caller_address) = get_caller_address()
        let (is_lead_contributor) = internal.is_lead_contributor(project_id, caller_address)

        with_attr error_message("Contributions: LEAD_CONTRIBUTOR role required"):
            assert_not_zero(is_lead_contributor)
        end
        
        return()
    end
end

namespace internal:
    func assert_not_caller{syscall_ptr : felt*}(address : felt):
        let (caller_address) = get_caller_address()
        assert_not_zero(caller_address - address)
        return ()
    end

    func is_lead_contributor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(project_id : felt, account: felt) -> (is_lead_contributor : felt):
        let (is_member) = has_role_by_project_and_account_.read(Role.LEAD_CONTRIBUTOR, project_id, account)
        return (is_member)
    end
end