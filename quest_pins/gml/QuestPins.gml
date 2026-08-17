// Quest Pins
// Fields of Mistria 1.0.3 / MOMI + MMAPI 0.15.5

#macro QUEST_PINS_VERSION "0.1.6"
#macro QUEST_PINS_CONFIG_VERSION 2
#macro QUEST_PINS_SAVE_VERSION 1
#macro QP_TRACKER_X -6
#macro QP_TRACKER_FALLBACK_Y 69
#macro QP_TRACKER_MARGIN_TOP 4
#macro QP_TRACKER_WIDTH_DEFAULT 160
#macro QP_TRACKER_WIDTH_MIN 88
#macro QP_TRACKER_WIDTH_MAX 240
#macro QP_CARD_GAP 4
#macro QP_PIN_ELEMENT_HEIGHT 28
#macro QP_PIN_BUTTON_WIDTH 116
#macro QP_PIN_BUTTON_HEIGHT 20

function __quest_pins_runtime() {
    if (global[$ "__quest_pins"] == undefined) {
        global.__quest_pins = {
            registered: false,
            initialized: false,
            config: undefined,
            pinned_quests: [],
            tracker_root: undefined,
            tracker_toolbar: undefined,
            tracker_info_hud: undefined,
            tracker_signature: "",
            alert_signature: "",
            tracker_dirty: true,
            item_counts: array_create(ItemId.LEN, -1),
            inventory_baselined: false,
        };
    }
    return global.__quest_pins;
}

function quest_pins_config() {
    var _rt = __quest_pins_runtime();
    if (_rt.config != undefined) {
        return _rt.config;
    }

    var _source = mmapi_config_read_valid("quest_pins", QUEST_PINS_CONFIG_VERSION);
    _rt.config = {
        enabled: mmapi_config_bool(_source, "enabled", true),
        max_pinned_quests: floor(mmapi_config_number(_source, "max_pinned_quests", 3, 1, 5)),
        tracker_width: floor(mmapi_config_number(
            _source,
            "tracker_width",
            QP_TRACKER_WIDTH_DEFAULT,
            QP_TRACKER_WIDTH_MIN,
            QP_TRACKER_WIDTH_MAX
        )),
        tracker_on_left: mmapi_config_bool(_source, "tracker_on_left", false),
        play_sound: mmapi_config_bool(_source, "play_sound", true),
        show_notifications: mmapi_config_bool(_source, "show_notifications", true),
        notify_all_active_quests: mmapi_config_bool(
            _source,
            "notify_all_active_quests",
            true
        ),
        debug_logging: mmapi_config_bool(_source, "debug_logging", false),
    };
    mmapi_config_write("quest_pins", QUEST_PINS_CONFIG_VERSION, _rt.config);
    return _rt.config;
}

function quest_pins_config_save() {
    var _rt = __quest_pins_runtime();
    mmapi_config_write("quest_pins", QUEST_PINS_CONFIG_VERSION, quest_pins_config());
    _rt.tracker_signature = "";
    _rt.tracker_dirty = true;
}

function quest_pins_debug(_message) {
    if (!quest_pins_config().debug_logging) {
        return;
    }
    mmapi_log_info("quest_pins", "[QP] " + _message);
    if (mmapi_io_is_ready()) {
        mmapi_log_flush("quest_pins");
    }
}

function quest_pins_register() {
    var _rt = __quest_pins_runtime();
    if (_rt.registered) {
        return;
    }
    _rt.registered = true;

    mmapi_on("ui.menu_opened", quest_pins_on_menu_opened);
    mmapi_on("ui.menu_refreshed", quest_pins_on_menu_refreshed);
    mmapi_modsave_register("quest_pins", quest_pins_save_collect, quest_pins_save_apply);
    mmapi_register(quest_pins_tick);
}

function quest_pins_save_collect() {
    var _rt = __quest_pins_runtime();
    var _pinned = [];
    for (var _i = 0; _i < array_length(_rt.pinned_quests); _i++) {
        array_push(_pinned, _rt.pinned_quests[_i]);
    }
    return {
        version: QUEST_PINS_SAVE_VERSION,
        pinned_quests: _pinned,
    };
}

function quest_pins_save_apply(_data) {
    var _rt = __quest_pins_runtime();
    _rt.pinned_quests = [];

    if (is_struct(_data)
        && _data[$ "version"] == QUEST_PINS_SAVE_VERSION
        && is_array(_data[$ "pinned_quests"]))
    {
        for (var _i = 0; _i < array_length(_data.pinned_quests); _i++) {
            var _key = _data.pinned_quests[_i];
            if (is_string(_key) && !array_contains(_rt.pinned_quests, _key)) {
                array_push(_rt.pinned_quests, _key);
            }
        }
    }

    _rt.item_counts = array_create(ItemId.LEN, -1);
    _rt.inventory_baselined = false;
    _rt.tracker_signature = "";
    _rt.alert_signature = "";
    _rt.tracker_dirty = true;
}

function quest_pins_tick() {
    var _rt = __quest_pins_runtime();
    if (!_rt.initialized) {
        _rt.initialized = true;
        quest_pins_config();
        mmapi_log_info("quest_pins", "[QP] Ready. Quest source: QUEST_LOG.active; item source: ARI.inventory");
    }

    if (!quest_pins_config().enabled || !instance_exists(obj_ari) || QUEST_LOG == undefined) {
        quest_pins_free_tracker();
        return;
    }

    if (quest_pins_prune_inactive()) {
        _rt.tracker_dirty = true;
    }

    var _signature = quest_pins_tracker_signature();
    if (_signature != _rt.tracker_signature) {
        _rt.tracker_signature = _signature;
        _rt.tracker_dirty = true;
    }

    var _alert_signature = quest_pins_alert_signature();
    if (_alert_signature != _rt.alert_signature) {
        _rt.alert_signature = _alert_signature;
        quest_pins_reset_alert_baseline();
    }

    var _toolbar = ANCHOR.get_menu(Menu.Toolbar);
    if (_toolbar != _rt.tracker_toolbar) {
        _rt.tracker_toolbar = _toolbar;
        _rt.tracker_dirty = true;
    }

    var _info_hud = ANCHOR.get_menu(Menu.InfoHud);
    if (_info_hud != _rt.tracker_info_hud) {
        _rt.tracker_info_hud = _info_hud;
        _rt.tracker_dirty = true;
    }

    quest_pins_update_tracker_position();

    if (!_rt.inventory_baselined) {
        quest_pins_sync_inventory(false);
    }

    if (_rt.tracker_dirty) {
        quest_pins_rebuild_tracker();
    }
}

function quest_pins_on_menu_opened(_ctx) {
    if (!quest_pins_config().enabled) {
        return;
    }
    if (_ctx.kind == Menu.QuestLog) {
        quest_pins_decorate_quest_log(_ctx.menu);
    } else if (_ctx.kind == Menu.Settings) {
        quest_pins_decorate_settings(_ctx.menu);
    } else if (_ctx.kind == Menu.Toolbar) {
        var _rt = __quest_pins_runtime();
        _rt.tracker_toolbar = _ctx.menu;
        _rt.tracker_dirty = true;
    }
}

function quest_pins_tracker_size_id() {
    var _width = quest_pins_config().tracker_width;
    if (_width <= 100) {
        return "compact";
    }
    if (_width <= 136) {
        return "small";
    }
    if (_width >= 224) {
        return "extra_large";
    }
    if (_width >= 184) {
        return "large";
    }
    return "medium";
}

function quest_pins_tracker_size_width(_size_id) {
    switch (_size_id) {
        case "compact": return 88;
        case "small": return 112;
        case "large": return 208;
        case "extra_large": return 240;
        default: return 160;
    }
}

function quest_pins_tracker_size_display(_size_id) {
    return quest_pins_localized_value("mods/quest_pins/ui/size_" + _size_id);
}

function quest_pins_tracker_size_select(_size_id) {
    quest_pins_config().tracker_width = quest_pins_tracker_size_width(_size_id);
    quest_pins_config_save();

    var _menu = ANCHOR.get_menu(Menu.Settings);
    if (_menu != undefined
        && _menu[$ "__quest_pins_size_button"] != undefined
        && !_menu[$ "__quest_pins_size_button"].freed)
    {
        _menu[$ "__quest_pins_size_button"].text_label.set_key(
            "mods/quest_pins/ui/size_" + _size_id
        );
    }
}

function quest_pins_open_size_popup() {
    var _menu = ANCHOR.get_menu(Menu.Settings);
    if (_menu == undefined) {
        return;
    }
    create_options_popup(
        "mods/quest_pins/ui/tracker_size",
        List("compact", "small", "medium", "large", "extra_large"),
        quest_pins_tracker_size_display,
        quest_pins_tracker_size_select,
        _menu.new_pilot()
    );
}

function quest_pins_sound_get(_key) {
    return quest_pins_config().play_sound;
}

function quest_pins_sound_toggle(_key) {
    quest_pins_config().play_sound = !quest_pins_config().play_sound;
    quest_pins_config_save();
}

function quest_pins_notifications_get(_key) {
    return quest_pins_config().show_notifications;
}

function quest_pins_notifications_toggle(_key) {
    quest_pins_config().show_notifications = !quest_pins_config().show_notifications;
    quest_pins_config_save();
}

function quest_pins_alert_scope_id() {
    return quest_pins_config().notify_all_active_quests ? "all_active" : "pinned_only";
}

function quest_pins_alert_scope_display(_scope_id) {
    return quest_pins_localized_value("mods/quest_pins/ui/scope_" + _scope_id);
}

function quest_pins_tracker_side_id() {
    return quest_pins_config().tracker_on_left ? "left" : "right";
}

function quest_pins_tracker_side_display(_side_id) {
    return quest_pins_localized_value("mods/quest_pins/ui/side_" + _side_id);
}

function quest_pins_localized_value(_key) {
    // Added GML does not reliably resolve injected keys through a direct
    // local_get/mmapi_local_get call. Vanilla Node.set_key does, so use a
    // short-lived text node for option values that need an immediate string.
    var _node = ANCHOR.text(ANCHOR.screen_canvas).set_key(_key);
    var _value = _node.get_text();
    ANCHOR.free_node(_node);
    return _value;
}

function quest_pins_tracker_side_select(_side_id) {
    quest_pins_config().tracker_on_left = (_side_id == "left");
    quest_pins_config_save();

    var _menu = ANCHOR.get_menu(Menu.Settings);
    if (_menu != undefined
        && _menu[$ "__quest_pins_side_button"] != undefined
        && !_menu[$ "__quest_pins_side_button"].freed)
    {
        _menu[$ "__quest_pins_side_button"].text_label.set_key(
            "mods/quest_pins/ui/side_" + _side_id
        );
    }
}

function quest_pins_open_tracker_side_popup() {
    var _menu = ANCHOR.get_menu(Menu.Settings);
    if (_menu == undefined) {
        return;
    }
    create_options_popup(
        "mods/quest_pins/ui/tracker_side",
        List("left", "right"),
        quest_pins_tracker_side_display,
        quest_pins_tracker_side_select,
        _menu.new_pilot()
    );
}

function quest_pins_alert_scope_select(_scope_id) {
    quest_pins_config().notify_all_active_quests = (_scope_id == "all_active");
    quest_pins_config_save();

    var _rt = __quest_pins_runtime();
    _rt.alert_signature = quest_pins_alert_signature();
    quest_pins_reset_alert_baseline();

    var _menu = ANCHOR.get_menu(Menu.Settings);
    if (_menu != undefined
        && _menu[$ "__quest_pins_scope_button"] != undefined
        && !_menu[$ "__quest_pins_scope_button"].freed)
    {
        _menu[$ "__quest_pins_scope_button"].text_label.set_key(
            "mods/quest_pins/ui/scope_" + _scope_id
        );
    }
}

function quest_pins_open_alert_scope_popup() {
    var _menu = ANCHOR.get_menu(Menu.Settings);
    if (_menu == undefined) {
        return;
    }
    create_options_popup(
        "mods/quest_pins/ui/item_alert_scope",
        List("all_active", "pinned_only"),
        quest_pins_alert_scope_display,
        quest_pins_alert_scope_select,
        _menu.new_pilot()
    );
}

function quest_pins_set_setting_title(_button, _key) {
    var _siblings = _button.parent.children;
    for (var _i = 0; _i < array_length(_siblings); _i++) {
        if (_siblings[_i].type == NodeId.Text) {
            _siblings[_i].set_key(_key);
            return;
        }
    }
}

function quest_pins_open_settings() {
    var _menu = ANCHOR.get_menu(Menu.Settings);
    if (_menu == undefined || _menu.option_scroller == undefined) {
        return;
    }

    var _help = _menu.element(
        "mods/quest_pins/ui/settings_help",
        44,
        false
    );
    _help.text_label
        .set_align(Align.LeftIn, Align.TopIn)
        .set_xy(7, 4)
        .set_max_width(210);

    var _size_button = _menu.button("quest_pins_tracker_size")
        .add_text_label(
            "mods/quest_pins/ui/size_" + quest_pins_tracker_size_id(),
            COMMON_LUT,
            CommonLutIndex.Dark
        )
        .set_tap_callback(quest_pins_open_size_popup);
    quest_pins_set_setting_title(_size_button, "mods/quest_pins/ui/tracker_size");
    _menu[$ "__quest_pins_size_button"] = _size_button;

    var _side_button = _menu.button("quest_pins_tracker_side")
        .add_text_label(
            "mods/quest_pins/ui/side_" + quest_pins_tracker_side_id(),
            COMMON_LUT,
            CommonLutIndex.Dark
        )
        .set_tap_callback(quest_pins_open_tracker_side_popup);
    quest_pins_set_setting_title(_side_button, "mods/quest_pins/ui/tracker_side");
    _menu[$ "__quest_pins_side_button"] = _side_button;

    var _scope_button = _menu.button("quest_pins_alert_scope")
        .add_text_label(
            "mods/quest_pins/ui/scope_" + quest_pins_alert_scope_id(),
            COMMON_LUT,
            CommonLutIndex.Dark
        )
        .set_tap_callback(quest_pins_open_alert_scope_popup);
    quest_pins_set_setting_title(_scope_button, "mods/quest_pins/ui/item_alert_scope");
    _scope_button.text_label
        .set_max_width(78)
        .prevent_spillover();
    _menu[$ "__quest_pins_scope_button"] = _scope_button;

    var _sound = _menu.checkbox(
        "quest_pins_sound",
        quest_pins_sound_get,
        quest_pins_sound_toggle
    );
    _sound.element.text_label.set_key("mods/quest_pins/ui/play_sound");

    var _notifications = _menu.checkbox(
        "quest_pins_notifications",
        quest_pins_notifications_get,
        quest_pins_notifications_toggle
    );
    _notifications.element.text_label.set_key("mods/quest_pins/ui/show_notifications");
}

function quest_pins_decorate_settings(_menu) {
    if (_menu[$ "__quest_pins_settings_decorated"] == true) {
        return;
    }
    _menu[$ "__quest_pins_settings_decorated"] = true;

    var _category = _menu.create_category(
        "quest_pins",
        quest_pins_open_settings,
        spr_ui_journal_magic_pin_icon
    );
    _category.text_label.set_key("mods/quest_pins/ui/settings_category");
}

function quest_pins_on_menu_refreshed(_ctx) {
    if (!quest_pins_config().enabled
        || _ctx.kind != Menu.Toolbar
        || !instance_exists(obj_ari))
    {
        return;
    }

    quest_pins_sync_inventory(true);
    __quest_pins_runtime().tracker_dirty = true;
}

function quest_pins_is_pinned(_quest_key) {
    return array_contains(__quest_pins_runtime().pinned_quests, _quest_key);
}

function quest_pins_toggle(_quest_key) {
    var _rt = __quest_pins_runtime();
    if (array_contains(_rt.pinned_quests, _quest_key)) {
        var _index = array_pos(_rt.pinned_quests, _quest_key);
        array_delete(_rt.pinned_quests, _index, 1);
        quest_pins_debug("Unpinned quest=" + _quest_key);
    } else {
        if (array_length(_rt.pinned_quests) >= quest_pins_config().max_pinned_quests) {
            create_notification("mods/quest_pins/ui/pin_limit_reached", 30);
            return false;
        }
        if (!QUEST_LOG.active.contains_key(_quest_key)) {
            return false;
        }
        array_push(_rt.pinned_quests, _quest_key);
        quest_pins_debug("Pinned quest=" + _quest_key);
    }

    _rt.tracker_signature = "";
    _rt.tracker_dirty = true;
    if (!quest_pins_config().notify_all_active_quests) {
        _rt.alert_signature = quest_pins_alert_signature();
        quest_pins_reset_alert_baseline();
    }
    return true;
}

function quest_pins_prune_inactive() {
    var _rt = __quest_pins_runtime();
    var _changed = false;
    for (var _i = array_length(_rt.pinned_quests) - 1; _i >= 0; _i--) {
        if (!QUEST_LOG.active.contains_key(_rt.pinned_quests[_i])) {
            array_delete(_rt.pinned_quests, _i, 1);
            _changed = true;
        }
    }
    return _changed;
}

function quest_pins_tracker_signature() {
    var _rt = __quest_pins_runtime();
    var _signature = "";
    for (var _i = 0; _i < array_length(_rt.pinned_quests); _i++) {
        var _key = _rt.pinned_quests[_i];
        var _active = QUEST_LOG.active.get(_key);
        if (_active != undefined) {
            _signature += _key + ":" + string(_active.current_stage) + ";";
        }
    }
    return _signature;
}

function quest_pins_alert_quest_keys() {
    if (quest_pins_config().notify_all_active_quests) {
        return QUEST_LOG.active.keys();
    }

    var _keys = [];
    var _pinned = __quest_pins_runtime().pinned_quests;
    for (var _i = 0; _i < array_length(_pinned); _i++) {
        array_push(_keys, _pinned[_i]);
    }
    return _keys;
}

function quest_pins_alert_signature() {
    if (QUEST_LOG == undefined) {
        return "";
    }

    var _signature = quest_pins_config().notify_all_active_quests ? "all:" : "pinned:";
    var _keys = quest_pins_alert_quest_keys();
    for (var _i = 0; _i < array_length(_keys); _i++) {
        var _key = _keys[_i];
        var _active = QUEST_LOG.active.get(_key);
        if (_active != undefined) {
            _signature += _key + ":" + string(_active.current_stage) + ";";
        }
    }
    return _signature;
}

function quest_pins_reset_alert_baseline() {
    var _rt = __quest_pins_runtime();
    _rt.item_counts = array_create(ItemId.LEN, -1);
    _rt.inventory_baselined = false;
    quest_pins_sync_inventory(false);
}

function quest_pins_needed_items() {
    var _needed_items = [];
    var _quest_keys = quest_pins_alert_quest_keys();
    for (var _p = 0; _p < array_length(_quest_keys); _p++) {
        var _quest_key = _quest_keys[_p];
        var _active = QUEST_LOG.active.get(_quest_key);
        if (_active == undefined
            || _active.current_stage < 0
            || _active.current_stage >= _active.quest.tasks.count())
        {
            continue;
        }

        var _task = _active.quest.tasks.get(_active.current_stage);
        var _requirements = _task.requirements[Requirement.HasItem];
        if (_requirements == undefined) {
            continue;
        }

        for (var _i = 0; _i < array_length(_requirements); _i++) {
            var _requirement = _requirements[_i];
            array_push(_needed_items, {
                quest_key: _quest_key,
                item_id: _requirement[0],
                needed: _requirement[1],
            });
        }
    }
    return _needed_items;
}

function quest_pins_sync_inventory(_notify) {
    var _rt = __quest_pins_runtime();
    if (!instance_exists(obj_ari) || QUEST_LOG == undefined) {
        return;
    }

    var _relevant = array_create(ItemId.LEN, false);
    var _current_counts = array_create(ItemId.LEN, -1);
    var _played_sound = false;
    var _needed_items = quest_pins_needed_items();

    // Resolve each relevant item count once. This keeps the same before/after
    // baseline available when one acquisition advances multiple active quests.
    for (var _i = 0; _i < array_length(_needed_items); _i++) {
        var _entry = _needed_items[_i];
        var _item_id = _entry.item_id;
        _relevant[_item_id] = true;
        if (_current_counts[_item_id] < 0) {
            _current_counts[_item_id] = ARI.inventory.item_id_quantity(_item_id);
        }
    }

    for (var _i = 0; _i < array_length(_needed_items); _i++) {
        var _entry = _needed_items[_i];
        var _quest_key = _entry.quest_key;
        var _item_id = _entry.item_id;
        var _needed = _entry.needed;
        var _current = _current_counts[_item_id];
        var _previous = _rt.item_counts[_item_id];

        if (_notify
            && _rt.inventory_baselined
            && _previous >= 0
            && _current > _previous
            && _previous < _needed)
        {
            if (quest_pins_config().show_notifications) {
                var _message = format(
                    "{Local}: {Local} - {Local}",
                    "mods/quest_pins/ui/quest_item_obtained",
                    ITEM_PROTOTYPES[_item_id].name_key,
                    QUESTS.get(_quest_key).name,
                );
                create_notification(ANCHOR.wrap_for_local(_message));
            }
            if (!_played_sound && quest_pins_config().play_sound) {
                var _sound = "SoundEffects/UI/UIExtraPositiveClick";
                if (TANGO.name_exists(_sound)) {
                    TANGO.play(_sound);
                }
                _played_sound = true;
            }
            quest_pins_debug(
                "Needed item gained: quest=" + _quest_key
                + " item=" + item_id_to_string(_item_id)
                + " previous=" + string(_previous)
                + " current=" + string(_current)
                + " needed=" + string(_needed)
            );
        }
    }

    for (var _i = 0; _i < ItemId.LEN; _i++) {
        if (_relevant[_i]) {
            _rt.item_counts[_i] = _current_counts[_i];
        } else {
            _rt.item_counts[_i] = -1;
        }
    }
    _rt.inventory_baselined = true;
}

function quest_pins_free_tracker() {
    var _rt = __quest_pins_runtime();
    if (_rt.tracker_root != undefined && !_rt.tracker_root.freed) {
        ANCHOR.free_node(_rt.tracker_root);
    }
    _rt.tracker_root = undefined;
}

function quest_pins_tracker_dynamic_y() {
    if (!quest_pins_config().tracker_on_left) {
        var _info_hud = ANCHOR.get_menu(Menu.InfoHud);
        if (_info_hud != undefined
            && _info_hud.bottom_backplate != undefined
            && !_info_hud.bottom_backplate.freed)
        {
            return _info_hud.bottom_backplate.get_y()
                + _info_hud.bottom_backplate.get_height()
                + QP_TRACKER_MARGIN_TOP;
        }
        return QP_TRACKER_FALLBACK_Y;
    }

    var _vitals = ANCHOR.get_menu(Menu.Vitals);
    if (_vitals == undefined
        || _vitals.root == undefined
        || _vitals.root.freed
        || !is_array(_vitals.occupied_space))
    {
        return QP_TRACKER_FALLBACK_Y;
    }

    var _bottom = _vitals.root.get_y();
    for (var _i = 0; _i < array_length(_vitals.occupied_space); _i++) {
        _bottom += _vitals.occupied_space[_i];
        if (_i < array_length(_vitals.occupied_space) - 1) {
            _bottom += VITAL_ELEMENT_SPACING;
        }
    }
    return _bottom + QP_TRACKER_MARGIN_TOP;
}

function quest_pins_update_tracker_position() {
    var _root = __quest_pins_runtime().tracker_root;
    if (_root == undefined || _root.freed) {
        return;
    }

    if (quest_pins_config().tracker_on_left) {
        _root.set_align(Align.LeftIn, Align.TopIn).set_x(3);
    } else {
        _root.set_align(Align.RightIn, Align.TopIn).set_x(QP_TRACKER_X);
    }
    _root.set_y(quest_pins_tracker_dynamic_y());
}

function quest_pins_rebuild_tracker() {
    var _rt = __quest_pins_runtime();
    quest_pins_free_tracker();
    _rt.tracker_dirty = false;

    var _toolbar = ANCHOR.get_menu(Menu.Toolbar);
    if (_toolbar == undefined
        || _toolbar.canvas == undefined
        || array_length(_rt.pinned_quests) == 0)
    {
        return;
    }

    var _tracker_width = quest_pins_config().tracker_width;
    var _tracker_y = quest_pins_tracker_dynamic_y();
    var _tracker_align = quest_pins_config().tracker_on_left
        ? Align.LeftIn
        : Align.RightIn;
    var _tracker_x = quest_pins_config().tracker_on_left ? 3 : QP_TRACKER_X;

    var _root = ANCHOR.positional(_toolbar.canvas)
        .set_size(_tracker_width, 1)
        .set_align(_tracker_align, Align.TopIn)
        .set_xy(_tracker_x, _tracker_y);
    _rt.tracker_root = _root;

    var _yy = 0;
    for (var _i = 0; _i < array_length(_rt.pinned_quests); _i++) {
        var _quest_key = _rt.pinned_quests[_i];
        var _active = QUEST_LOG.active.get(_quest_key);
        if (_active == undefined
            || _active.current_stage < 0
            || _active.current_stage >= _active.quest.tasks.count())
        {
            continue;
        }

        var _quest = _active.quest;
        var _task = _quest.tasks.get(_active.current_stage);
        var _card = ANCHOR.positional(_root)
            .set_size(_tracker_width, 1)
            .set_y(_yy);

        var _header = ANCHOR.nine_slice(_card)
            .set_size(_tracker_width, 21)
            .set_sprites_from_key("spr_ui_generic_box_header")
            .add_text_label(_quest.name, COMMON_LUT, CommonLutIndex.Header);
        _header.text_label
            .set_align(Align.LeftIn, Align.Middle)
            .set_x(21)
            .allow_line_breaks(false);
        quest_pins_fit_single_line(_header.text_label, _tracker_width - 27);
        ANCHOR.sprite(_header)
            .set_sprite(spr_ui_journal_magic_pin_icon)
            .set_align(Align.LeftIn, Align.Middle)
            .set_x(4);

        var _body = ANCHOR.nine_slice(_card)
            .set_y(20)
            .set_size(_tracker_width, 20)
            .set_sprite(spr_ui_generic_box_main);
        var _objective = ANCHOR.text(_body)
            .set_key(_task.description)
            .set_align(Align.LeftIn, Align.TopIn)
            .set_xy(5, 5)
            .set_max_width(_tracker_width - 10)
            .set_lut(COMMON_LUT);
        var _body_y = 5 + _objective.measure().y + 4;

        var _requirements = _task.requirements[Requirement.HasItem];
        if (_requirements != undefined) {
            for (var _r = 0; _r < array_length(_requirements); _r++) {
                var _requirement = _requirements[_r];
                var _listing = Listing.Item(_requirement[0], ARI.inventory, _requirement[1]);
                var _row = ANCHOR.positional(_body)
                    .set_xy(4, _body_y)
                    .set_size(_tracker_width - 8, 18);
                var _nodes = render_quest_requirement(
                    _listing,
                    _row,
                    max(24, _tracker_width - 62)
                );
                var _row_height = max(18, _nodes.name.measure().y + 5);
                _row.set_height(_row_height);
                _body_y += _row_height;
            }
        }

        var _body_height = _body_y + 4;
        _body.set_height(_body_height);
        var _card_height = 20 + _body_height;
        _card.set_height(_card_height);
        _yy += _card_height + QP_CARD_GAP;
    }
    _root.set_height(max(1, _yy));
}

function quest_pins_fit_single_line(_text_node, _max_width) {
    _text_node.allow_line_breaks(false);
    if (_text_node.measure().x <= _max_width) {
        return;
    }

    var _full_text = _text_node.get_text();
    var _suffix = "...";
    for (var _length = string_length(_full_text) - 1; _length > 0; _length--) {
        _text_node.set_text(string_copy(_full_text, 1, _length) + _suffix);
        if (_text_node.measure().x <= _max_width) {
            return;
        }
    }
    _text_node.set_text(_suffix);
}

function quest_pins_move_control_before_rewards(_scroller, _element) {
    var _children = _scroller.root.children;
    var _element_index = array_pos(_children, _element);
    var _rewards_index = -1;

    for (var _i = 0; _i < _element_index; _i++) {
        var _candidate = _children[_i];
        if (_candidate.text_label != undefined
            && _candidate.text_label.get_display_key() == "misc_local/rewards")
        {
            _rewards_index = _i;
            break;
        }
    }
    if (_rewards_index < 0) {
        return;
    }

    var _spacing = _element.get_height() - 1;
    var _target_y = _children[_rewards_index].get_y();
    for (var _i = _rewards_index; _i < _element_index; _i++) {
        _children[_i].add_y(_spacing);
    }
    _element.set_y(_target_y);
    array_delete(_children, _element_index, 1);
    array_insert(_children, _rewards_index, _element);
}

function quest_pins_button_key(_quest_key) {
    return quest_pins_is_pinned(_quest_key)
        ? "mods/quest_pins/ui/unpin_quest"
        : "mods/quest_pins/ui/pin_quest";
}

function quest_pins_add_control(_menu, _quest_key) {
    var _scroller = _menu.right_scroller;
    if (_scroller == undefined || _quest_key == undefined) {
        return undefined;
    }

    var _element = _scroller.new_element(QP_PIN_ELEMENT_HEIGHT)
        .set_sprite(spr_nothing_nineslice);
    var _button = ANCHOR.nine_slice(_element)
        .set_size(QP_PIN_BUTTON_WIDTH, QP_PIN_BUTTON_HEIGHT)
        .set_align(Align.Center, Align.Middle)
        .set_sprites_from_key("spr_ui_button")
        .set_tap_sound("SoundEffects/UI/UIExtraPositiveClick")
        .add_text_label(quest_pins_button_key(_quest_key), COMMON_LUT, CommonLutIndex.Dark)
        .add_hover_outline()
        .add_to_pilot(_menu.right_pilot, true)
        .set_selected_getter(function(_key) {
            return quest_pins_is_pinned(_key);
        }, [_quest_key]);

    var _control = {
        element: _element,
        button: _button,
        quest_key: _quest_key,
        scroller: _scroller,
    };
    _button.set_tap_callback(function(_key, _this_control) {
        if (quest_pins_toggle(_key)) {
            quest_pins_update_control(_this_control, _key);
        }
    }, [_quest_key, _control], true);
    _button.text_label
        .set_x(5)
        .set_max_width(QP_PIN_BUTTON_WIDTH - 22)
        .prevent_spillover();
    ANCHOR.sprite(_button)
        .set_sprite(spr_ui_journal_magic_pin_icon)
        .set_align(Align.LeftIn, Align.Middle)
        .set_x(5);

    quest_pins_update_control(_control, _quest_key);
    quest_pins_move_control_before_rewards(_scroller, _element);
    return _control;
}

function quest_pins_update_control(_control, _quest_key) {
    if (_control == undefined
        || _control.element.freed
        || _control.button.freed)
    {
        return undefined;
    }

    _control.quest_key = _quest_key;
    _control.button.text_label.set_key(quest_pins_button_key(_quest_key));
    _control.button.set_selected_getter(function(_key) {
        return quest_pins_is_pinned(_key);
    }, [_quest_key]);
    _control.button.set_tap_callback(function(_key, _this_control) {
        if (quest_pins_toggle(_key)) {
            quest_pins_update_control(_this_control, _key);
        }
    }, [_quest_key, _control], true);

    var _can_pin = quest_pins_is_pinned(_quest_key)
        || array_length(__quest_pins_runtime().pinned_quests) < quest_pins_config().max_pinned_quests;
    _control.button.set_unlocked(_can_pin);
    _control.button.set_alpha(_can_pin ? 1 : UI_FADE_ALPHA);
    return _control;
}

function quest_pins_decorate_quest_log(_menu) {
    if (_menu.context != QuestLogContext.Journal
        || _menu[$ "__quest_pins_decorated"] == true)
    {
        return;
    }
    _menu[$ "__quest_pins_decorated"] = true;

    var _watcher = ANCHOR.positional(_menu.journal.book).set_size(0, 0);
    _watcher.board_set("last_quest", undefined);
    _watcher.board_set("last_scroller", undefined);
    _watcher.board_set("last_pinned", undefined);
    _watcher.board_set("last_count", -1);
    _watcher.board_set("control", undefined);
    _watcher.set_think_callback(function(_node, _quest_menu) {
        var _quest_key = _quest_menu.active_quest;
        var _scroller = _quest_menu.right_scroller;
        var _is_pinned = quest_pins_is_pinned(_quest_key);
        var _count = array_length(__quest_pins_runtime().pinned_quests);
        if (_node.board_get("last_quest") == _quest_key
            && _node.board_get("last_scroller") == _scroller
            && _node.board_get("last_pinned") == _is_pinned
            && _node.board_get("last_count") == _count)
        {
            return;
        }

        var _old_scroller = _node.board_get("last_scroller");
        var _control = _node.board_get("control");
        _node.board_set("last_quest", _quest_key);
        _node.board_set("last_scroller", _scroller);
        _node.board_set("last_pinned", _is_pinned);
        _node.board_set("last_count", _count);

        if (_control != undefined && _old_scroller == _scroller) {
            _node.board_set("control", quest_pins_update_control(_control, _quest_key));
            return;
        }

        _node.board_set("control", undefined);
        if (_quest_key != undefined && _scroller != undefined) {
            _node.board_set("control", quest_pins_add_control(_quest_menu, _quest_key));
        }
    }, [_watcher, _menu]);
}

mmapi_mod_declare("quest_pins", QUEST_PINS_VERSION);
quest_pins_register();
