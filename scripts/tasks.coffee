module.exports = (robot) ->
  getTrello = ->
    appKey    = process.env.HUBOT_TASKS_APP_KEY
    userToken = process.env.HUBOT_TASKS_USER_TOKEN
    Trello = require('trello')
    return new Trello appKey, userToken

  calculateTaskPoint = (targetListId) ->
    trello = getTrello()
    points = 0
    cards = trello.getCardsForList targetListId
    cards.
      then (tasks) ->
        for task in tasks
          if task.name.match /^【.*?(\d+)pt】.*/
            points += Number(RegExp.$1)
        return points

  cleanTask = (targetListId, dailyTaskListId, weeklyTaskListId) ->
    trello = getTrello()
    cards = trello.getCardsForList targetListId
    cards.
      then (tasks) ->
        for task in tasks
          if task.name.match /^【D-(\d+)pt】.*/
            trello.updateCardList task.id, dailyTaskListId
          else if task.name.match /^【W-(\d+)pt】.*/
            trello.updateCardList task.id, weeklyTaskListId
          else if task.name.match /^【(\d+)pt】.*/
            trello.deleteCard task.id

  # Trelloにタスク追加
  robot.respond /(todo|task) add (.*)/i, (msg) ->
    boardName = process.env.HUBOT_TASKS_BOARD_NAME
    listName  = process.env.HUBOT_TASKS_LIST_NAME
    userId    = process.env.HUBOT_TASKS_USER_ID
    task      = msg.match[2]

    trello = getTrello()

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

  # Trelloのポイントを計算
  robot.respond /(todo|task) calc/i, (msg) ->
    userId    = process.env.HUBOT_TASKS_USER_ID
    doneList1  = process.env.HUBOT_TASKS_USER_TASK_LIST1
    doneList2  = process.env.HUBOT_TASKS_USER_TASK_LIST2
    boardName = process.env.HUBOT_TASKS_BOARD_NAME

    trello      = getTrello()

    getBoards = trello.getBoards userId
    getBoards
      .then (boards) ->
        for board in boards
          if board.name == boardName
            return board.id
      .then (bId) ->
        getLists = trello.getListsOnBoard bId
        getLists
          .then (lists) ->
            for list in lists
              switch list.name
                when doneList1
                  userPoint = calculateTaskPoint list.id
                  userPoint
                    .then (point) ->
                      msg.send "#{list.name}: #{point} pt"
                when doneList2
                  userPoint = calculateTaskPoint list.id
                  userPoint
                    .then (point) ->
                      msg.send "#{list.name}: #{point} pt"
          .catch (error) ->
            msg.send 'Listの取得に失敗したで', error

  # Trelloのタスクを清算
  robot.respond /(todo|task) clean/i, (msg) ->
    userId      = process.env.HUBOT_TASKS_USER_ID
    boardName   = process.env.HUBOT_TASKS_BOARD_NAME
    doneList1   = process.env.HUBOT_TASKS_USER_TASK_LIST1
    doneList2   = process.env.HUBOT_TASKS_USER_TASK_LIST2
    dailyTask   = process.env.HUBOT_TASKS_DAILY_TASK_LIST
    weekendTask = process.env.HUBOT_TASKS_WEEKEND_TASK_LIST

    trello           = getTrello()

    getBoards = trello.getBoards userId
    getBoards
      .then (boards) ->
        for board in boards
            if board.name == boardName
              return board.id
      .then (bId) ->
        getLists = trello.getListsOnBoard bId
        getLists
          .then (lists) ->
            vars = []
            for list in lists
              switch list.name
                when doneList1
                  vars["user1"] = list
                when doneList2
                  vars["user2"] = list
                when dailyTask
                  vars["daily"] = list
                when weekendTask
                  vars["weekend"] = list
            return vars

          .then (lists) ->
            user1   = lists["user1"]
            user2   = lists["user2"]
            daily   = lists["daily"]
            weekend = lists["weekend"]

            userPoint = calculateTaskPoint user1.id
            userPoint
              .then (point) ->
                msg.send "#{user1.name}: #{point} pt"
              .then (_) ->
                cleanTask user1.id, daily.id, weekend.id

            userPoint = calculateTaskPoint user2.id
            userPoint
              .then (point) ->
                msg.send "#{user2.name}: #{point} pt"
              .then (_) ->
                cleanTask user2.id, daily.id, weekend.id

          .catch (error) ->
            msg.send 'Listの取得に失敗したで', error

