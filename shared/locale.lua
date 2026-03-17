-- Built-in locale for boss/gang menus (no ox_lib locale files needed)
Locale = {
    boss = {
        cl_1 = 'Boss Menu', cl_2 = 'Manage Employees', cl_3 = 'Check your Employees List',
        cl_4 = 'Hire Employees', cl_5 = 'Hire Nearby Civilians', cl_6 = 'Storage Access',
        cl_7 = 'Open Storage', cl_8 = 'Money Management', cl_9 = 'Check your Company Balance',
        cl_10 = 'Employee List', cl_11 = 'set grade as', cl_12 = 'Grade', cl_13 = 'Fire Employee',
        cl_14 = 'Manage Employee', cl_15 = 'Citizen ID', cl_16 = 'ID', cl_17 = 'Balance',
        cl_18 = 'Deposit', cl_19 = 'deposit money into your account', cl_20 = 'Withdraw',
        cl_21 = 'withdraw money from your account', cl_22 = 'Available Balance', cl_23 = 'Amount',
        cl_open = 'Open',
        sv_storage = 'Boss Storage', sv_24 = 'boss menu withdraw', sv_25 = 'Withdraw Money',
        sv_26 = 'Withdrawal', sv_27 = 'You have withdrawn', sv_28 = 'You dont have enough money in the account!',
        sv_29 = 'Deposit Money', sv_30 = 'Deposit', sv_31 = 'You have deposited',
        sv_32 = 'You dont have enough money to add!', sv_33 = 'You cannot promote to this rank!',
        sv_34 = 'Successfully promoted!', sv_35 = 'You have been promoted to', sv_36 = 'Grade does not exist!',
        sv_37 = 'Civilian not in server', sv_38 = 'You cannot fire this citizen!', sv_39 = 'Job Fire',
        sv_40 = 'successfully fired ', sv_41 = 'Employee fired!', sv_42 = 'You have been fired! Good luck.',
        sv_43 = 'Error..', sv_44 = "You can't fire yourself", sv_45 = 'You cannot fire this citizen!',
        sv_46 = 'You hired', sv_47 = 'come', sv_48 = 'You were hired as', sv_49 = 'Recruit', sv_50 = ' successfully recruited ',
    },
    gang = {
        cl_1 = 'Gang Menu', cl_2 = 'Manage Members', cl_3 = 'Check your Member List',
        cl_4 = 'Hire Gang Members', cl_5 = 'Hire Nearby Civilians', cl_6 = 'Storage Access',
        cl_7 = 'Open Storage', cl_8 = 'Money Management', cl_9 = 'Check your Gang Balance',
        cl_10 = 'Member List', cl_11 = 'set grade as', cl_12 = 'Grade', cl_13 = 'Fire Member',
        cl_14 = 'Manage Gang Members', cl_15 = 'Citizen ID', cl_16 = 'ID', cl_17 = 'Balance',
        cl_18 = 'Deposit', cl_19 = 'deposit money into your account', cl_20 = 'Withdraw',
        cl_21 = 'withdraw money from your account', cl_22 = 'Available Balance', cl_23 = 'Amount',
        cl_open = 'Open ', cl_cmd_error = 'You must be a gang boss',
        sv_storage = 'Gang Storage', sv_24 = 'gang menu withdraw', sv_25 = 'Withdraw Money',
        sv_26 = 'Withdrawal $', sv_27 = 'You have withdrawn', sv_28 = "You dont have enough money in the account!",
        sv_29 = 'Deposit Money', sv_30 = 'Deposit $', sv_31 = 'You have deposited',
        sv_32 = "You dont have enough money to add!", sv_33 = "You cannot promote to this rank!",
        sv_34 = 'Successfully promoted!', sv_35 = 'You have been promoted to', sv_36 = 'Grade does not exist!',
        sv_37 = 'Civilian not in server', sv_38 = 'You cannot fire this citizen!', sv_39 = 'Member Fire',
        sv_40 = 'successfully fired', sv_41 = 'Member fired!', sv_42 = 'You have been expelled from the gang!',
        sv_43 = 'Error..', sv_44 = "You can't kick yourself out of the gang!", sv_45 = 'You cannot fire this citizen!',
        sv_46 = 'You hired', sv_47 = 'come', sv_48 = 'You were hired as', sv_49 = 'Recruit', sv_50 = 'successfully recruited',
        sv_51 = 'successfully withdrew', sv_52 = 'successfully deposited $',
        sv_admin_remove = 'Player removed from gang', sv_admin_error = 'Player not found',
        sv_admin_noperm = "You don't have permission", sv_admin_usage = 'Usage: /removegang [player id] [gang id]',
        sv_admin_invalidgangid = 'Invalid Gang ID',
    },
}

function locale(section, key)
    local t = Locale[section]
    return (t and t[key]) or key
end
