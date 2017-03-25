
import Foundation

class TeamDataSource: TableDataSource {
  var cells = [CellInfo]()

  func reload(completion: @escaping SuccessBlock) {
    // TODO: Fetch team from backend

    if cells.isEmpty {
      self.cells.append(TeamNameCellInfo(name: "Team Name"))
      Facebook.getTaggableFriends { (friend) in
        if self.cells.count > 12 { return }

        self.cells.append(TeamMemberCellInfo(name: friend.name, picture: friend.picture_url))
        onMain {
          completion(true)
        }
      }
    }
  }

  func addTeamMember(completion: @escaping SuccessBlock) {
    // TODO: Push data to backend and refresh cells

    // cells.append(TeamMemberCellInfo(name: "Someone New"))

    onMain {
      completion(true)
    }
  }
}
