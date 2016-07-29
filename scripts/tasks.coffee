module.exports = (robot) ->
  robot.respond /(todo|task|たすく|タスク) (.*)/i, (msg) ->
    appKey    = process.env.HUBOT_TASKS_APP_KEY
    userToken = process.env.HUBOT_TASKS_USER_TOKEN
    userId    = process.env.HUBOT_TASKS_USER_ID
    boardName = process.env.HUBOT_TASKS_BOARD_NAME
    listName  = process.env.HUBOT_TASKS_LIST_NAME
    task      = msg.match[2]

    Trello = require('trello')
    trello = new Trello appKey, userToken

    getBoards = trello.getBoards userId
    getBoards
      .then (boards) ->
        for board in boards
          if board.name ==  boardName
            return board.id
      .then (bId) ->
        getLists = trello.getListsOnBoard bId
        getLists
          .then (lists) ->
            for list in lists
              if list.name == listName
                return list.id
          .catch (error) ->
            msg.send 'Listの取得に失敗したで', error
        .then (lId) ->
          trello.addCard task, '', lId, (error, trelloCard) ->
              if error
                    msg.send 'Trelloの登録に失敗したで', error
              else
                    msg.send 'Trelloに登録したで'
          return
        .catch (error) ->
          msg.send 'Trelloの登録に失敗したで', error
