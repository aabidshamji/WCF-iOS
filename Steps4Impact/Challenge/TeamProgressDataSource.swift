/**
 * Copyright © 2019 Aga Khan Foundation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 **/

import Foundation
import RxSwift

enum TeamProgressSettingsContext: Context {
  case invite
  case delete
  case editname
}

enum TeamProgressMembersContext: Context {
  case remove(fbid: String, name: String)
}

protocol TeamProgressDataSourceDelegate: class {
  func updated(team: Team?)
}

class TeamProgressDataSource: TableViewDataSource {
  var cache = Cache.shared
  var facebookService = FacebookService.shared
  var disposeBag = DisposeBag()
  var cells: [[CellContext]] = []
  var completion: (() -> Void)?
  

  struct Member {
    let fbid: String?
    let name: String?
    let image: URL?
    let isLead: Bool
    let records : [Record]
  }

  private var teamName: String = " "
  private var eventName: String = " "
  private var eventTeamLimit: Int = 0
  private var team: [Member] = []
  private var teamMembers: [Participant] = []
  private var isLead: Bool = false

  var editing: Bool = false
  public weak var delegate: TeamProgressDataSourceDelegate?

  init() {
    let update = Observable.combineLatest(
      cache.facebookNamesRelay,
      cache.facebookProfileImageURLsRelay,
      cache.participantRelay,
      cache.currentEventRelay
    )

    update.subscribeOnNext { [weak self] (names, imageURLs, participant, currentEvent) in
      guard let participant = participant else { return }
      self?.delegate?.updated(team: participant.team)
      self?.isLead = participant.team?.creator == self?.facebookService.id
      self?.teamName = participant.team?.name ?? " "

      if let event = participant.currentEvent {
        self?.eventName = event.name
        self?.eventTeamLimit = event.teamLimit
        let members = participant.team?.members.map {
          Member(fbid: $0.fbid,
                 name: names[$0.fbid],
                 image: imageURLs[$0.fbid],
                 isLead: $0.fbid == participant.team?.creator,
                 records: $0.records ?? [])
        }
        self?.team = members ?? []
      }

      self?.configure()
      self?.completion?()
    }.disposed(by: disposeBag)
  }

  func reload(completion: @escaping () -> Void) {
    self.completion = completion
    configure()
    completion()

    AKFCausesService.getParticipant(fbid: facebookService.id) { [weak self] (result) in
      let participant = Participant(json: result.response)
      self?.cache.participantRelay.accept(participant)

      if let eventId = participant?.currentEvent?.id {
        AKFCausesService.getEvent(event: eventId) { (result) in
          self?.cache.currentEventRelay.accept(Event(json: result.response))
        }
      }
      
      self?.teamMembers = []

      if let team = participant?.team {
        for teamMember in team.members {
          self?.facebookService.getRealName(fbid: teamMember.fbid)
          self?.facebookService.getProfileImageURL(fbid: teamMember.fbid)
          
          AKFCausesService.getParticipant(fbid: teamMember.fbid) { [weak self] (result) in
            let newParticipant = Participant(json: result.response)
            
            self?.teamMembers.append(newParticipant!)
            
          }
          
        }
      }
    }
  }

  func configure() {
    
    var teamTotalSteps = 0
    
    teamTotalSteps = teamMembers.reduce(0, { (total, team) -> Int in
      guard let records = team.records else { return total + 0 }
      var sum = 0
      for record in records {
        sum += (record.distance ?? 0)
      }
      return total + sum
    })
    
    var teamTotalCommitment = 0
    
    teamTotalCommitment = teamMembers.reduce(0, { (total, team) -> Int in
      guard let commitment = team.currentEvent?.commitment?.miles else { return total + 0 }
      return total + commitment
    })
    
    var teamText = ""
    
    if teamTotalSteps == 0 {
      teamText = "0 \(Strings.Challenge.TeamProgress.miles)"
    } else {
      teamText = "\((teamTotalSteps / 2000) as Int) / \(teamTotalCommitment) mi"
    }
    
    cells = [[
      TeamSettingsHeaderCellContext(team: Strings.Challenge.TeamProgress.totalWalked, event: teamText),
      SettingsTitleCellContext(title: "Team Members")
    ]]
    
    var imageURLS : [String:URL] = [:]
    var names : [String:String] = [:]
    
    for member in self.team {
      imageURLS[member.fbid ?? ""] = member.image
      names[member.fbid ?? ""] = member.name
    }
    
    for (index, member) in self.teamMembers.enumerated() {
      var context: Context?
      let fbid = member.fbid
      
      context = TeamProgressMembersContext.remove(fbid: fbid, name: names[fbid] ?? "")
      
      var memberTotalSteps = 0

      for record in member.records ?? [] {
        memberTotalSteps += (record.distance ?? 0)
      }
      
      var memberMiles = 0
      
      if memberTotalSteps != 0 {
        memberMiles = (memberTotalSteps / 2000) as Int
      }
      
      let commitedMiles = member.currentEvent?.commitment?.miles

      cells.append([
        TeamProgressMemberCellContext(count: index + 1,
        imageURL: imageURLS[fbid],
        name: names[fbid] ?? "",
        progress: memberMiles,
        commitment: commitedMiles ?? 0,
        isLastItem: index == self.team.count - 1,
        context: context)
      ])
    }
  }
}
