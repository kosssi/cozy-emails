{section, header, ul, li, span, i, p, h3, a, button} = React.DOM
Message = require './message'
Toolbar = require './toolbar_conversation'
classer = React.addons.classSet
{MessageFlags} = require '../constants/app_constants'

RouterMixin = require '../mixins/router_mixin'
StoreWatchMixin = require '../mixins/store_watch_mixin'
ShouldComponentUpdate = require '../mixins/should_update_mixin'

LayoutActionCreator = require '../actions/layout_action_creator'
SettingsStore = require '../stores/settings_store'
AccountStore = require '../stores/account_store'
MessageStore = require '../stores/message_store'
LayoutStore = require '../stores/layout_store'


uniq = 1

module.exports = React.createClass
    displayName: 'Conversation'

    mixins: [
        RouterMixin,
        StoreWatchMixin [SettingsStore, AccountStore, MessageStore, LayoutStore]
        ShouldComponentUpdate.UnderscoreEqualitySlow
    ]

    propTypes:
        messageID: React.PropTypes.string

    getStateFromStores: ->
        message = MessageStore.getByID @props.messageID
        selectedMailboxID = AccountStore.getSelectedMailbox()?.get 'id'
        selectedAccount = AccountStore.getSelectedOrDefault()

        if message?
            conversationID = message?.get('conversationID')
            trashMailboxID = selectedAccount?.get('trashMailbox')
            conversation = MessageStore
                           .getConversation conversationID, trashMailboxID
            prevMessage = MessageStore.getPreviousMessage()
            nextMessage = MessageStore.getNextMessage()
            length = MessageStore.getConversationsLength().get conversationID
            selectedMailboxID ?= Object.keys(message.get('mailboxIDs'))[0]

        displayConvs = AccountStore.hasConversationEnabled selectedMailboxID
        displayConvs and= SettingsStore.get 'displayConversation'


        nextState =
            accounts             : AccountStore.getAll()
            mailboxes            : AccountStore.getAllMailboxes()
            selectedAccount      : AccountStore.getSelectedOrDefault()
            selectedMailboxID    : selectedMailboxID
            settings             : SettingsStore.get()
            useIntents           : LayoutStore.intentAvailable()
            conversationID       : conversationID
            conversation         : conversation
            conversationLength   : length
            prevMessage          : prevMessage
            nextMessage          : nextMessage
            displayConversations : displayConvs

        nextState.compact = true if @state?.compact isnt false

        if nextState.conversation?.length isnt @state?.conversation?.length
            nextState.expanded = []
            conversation?.forEach (message, key) ->
                isUnread = MessageFlags.SEEN not in message.get 'flags'
                isLast   = key is conversation.length - 1
                if (nextState.expanded.length is 0 and (isUnread or isLast))
                    nextState.expanded.push key
            nextState.compact = true

        return nextState

    renderToolbar: ->
        Toolbar
            nextMessageID       : @state.nextMessage?.get('id')
            nextConversationID  : @state.nextMessage?.get('conversationID')
            prevMessageID       : @state.prevMessage?.get('id')
            prevConversationID  : @state.prevMessage?.get('conversationID')
            settings            : @state.settings

    renderMessage: (key, active) ->
        # allow the Message component to update current active message
        # in conversation. Needed to open the first unread message when
        # opening a conversation
        toggleActive = =>
            expanded = @state.expanded[..]
            if key in expanded
                expanded = expanded.filter (id) -> return key isnt id
            else
                expanded.push key
            @setState expanded: expanded

        Message
            ref                 : 'message'
            accounts            : @state.accounts
            active              : active
            inConversation      : @state.conversation.length > 1
            key                 : key.toString()
            mailboxes           : @state.mailboxes
            message             : @state.conversation.get key
            selectedAccountID   : @state.selectedAccount.get 'id'
            selectedAccountLogin: @state.selectedAccount.get 'login'
            selectedMailboxID   : @state.selectedMailboxID
            settings            : @state.settings
            displayConversations: @state.displayConversation
            useIntents          : @state.useIntents
            toggleActive        : toggleActive


    renderGroup: (messages, key) ->
        # if there are more than 3 messages, by default only render
        # first and last ones
        if messages.length > 3 and @state.compact
            items = []
            [first, ..., last] = messages
            items.push @renderMessage(first, false)
            items.push button
                className: 'more'
                onClick: =>
                    @setState compact: false
                i className: 'fa fa-refresh'
                t 'load more messages', messages.length - 2
            items.push @renderMessage(last, false)
        else
            items = (@renderMessage(key, false) for key in messages)

        return items


    render: ->
        if not @state.conversation
            return section
                key: 'conversation'
                className: 'conversation panel'
                'aria-expanded': true,
                p null, t "app loading"

        message = @state.conversation.get 0
        # Sort messages in conversation to find seen messages and group them
        messages = []
        lastMessageIndex = @state.conversation.length - 1
        @state.conversation.forEach (message, key) =>
            if key in @state.expanded
                messages.push key
            else
                [..., last] = messages
                messages.push(last = []) unless _.isArray(last)
                last.push key

        # Starts components rendering
        section
            ref: 'conversation'
            className: 'conversation panel'
            'aria-expanded': true,

            header null,
                h3
                    className: 'conversation-title'
                    'data-message-id': message.get 'id'
                    'data-conversation-id': message.get 'conversationID'
                    message.get 'subject'
                @renderToolbar()
                a
                    className: 'clickable btn btn-default fa fa-close'
                    href: @buildClosePanelUrl 'second'
                    onClick: LayoutActionCreator.minimizePreview

            for glob, index in messages
                if _.isArray glob
                    @renderGroup glob, index
                else
                    @renderMessage glob, true
