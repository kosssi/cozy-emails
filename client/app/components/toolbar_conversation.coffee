{nav, div, button, a} = React.DOM
{Tooltips}            = require '../constants/app_constants'
classer               = React.addons.classSet

LayoutStore = require '../stores/layout_store'

LayoutActionCreator = require '../actions/layout_action_creator'

RouterMixin     = require '../mixins/router_mixin'
StoreWatchMixin = require '../mixins/store_watch_mixin'


module.exports = React.createClass
    displayName: 'ToolbarConversation'

    mixins: [
        RouterMixin
        StoreWatchMixin [LayoutStore]
    ]

    propTypes:
        nextMessageID       : React.PropTypes.string
        nextConversationID  : React.PropTypes.string
        prevMessageID       : React.PropTypes.string
        prevConversationID  : React.PropTypes.string
        settings            : React.PropTypes.object.isRequired

    getStateFromStores: ->
        fullscreen: LayoutStore.isPreviewFullscreen()


    getUrlParams: (messageID, conversationID) ->
        if @props.settings.get 'displayConversation' and conversationID?
            action = 'conversation'
            parameters =
                messageID: messageID
                conversationID: conversationID
        else
            action = 'message'
            parameters =
                messageID: messageID

        return urlParams =
            direction: 'second'
            action: action
            parameters: parameters


    render: ->
        nav className: 'toolbar toolbar-conversation btn-toolbar',
            div className: 'btn-group',
                @renderNav 'prev'
                @renderNav 'next'
            @renderFullscreen()


    renderNav: (direction) ->
        return unless @props["#{direction}MessageID"]?

        messageID = @props["#{direction}MessageID"]
        conversationID = @props["#{direction}ConversationID"]

        if direction is 'prev'
            tooltipID = Tooltips.PREVIOUS_CONVERSATION
            angle = 'left'
        else
            tooltipID = Tooltips.NEXT_CONVERSATION
            angle = 'right'

        urlParams = @getUrlParams messageID, conversationID

        a
            className: "btn btn-default fa fa-chevron-#{angle}"
            onClick: => @redirect urlParams
            href: @buildUrl urlParams
            'aria-describedby': tooltipID
            'data-tooltip-direction': 'left'


    renderFullscreen: ->
        button
            onClick: LayoutActionCreator.toggleFullscreen
            className: classer
                clickable:     true
                btn:           true
                'btn-default': true
                fa:            true
                fullscreen:    true
                'fa-compress': @state.fullscreen
                'fa-expand':   not @state.fullscreen
