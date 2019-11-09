//
//  BadgeCollectionDataSource.swift
//  Steps4Impact
//
//  Created by Aalim Mulji on 11/4/19.
//  Copyright © 2019 AKDN. All rights reserved.
//

import Foundation
import UIKit

class BadgesCollectionDataSource : CollectionViewDataSource {

  var completion: (() -> Void)?
  var refresh : Bool = true
  var dataSource : BadgesCollectionDataSource?
  var records: [Record]? {
    didSet {
        self.records = self.records?.sorted(by: { (r1, r2) -> Bool in
            if let d1 = r1.date, let d2 = r2.date {
                if d1 > d2 {
                    return true
                }
            }
            return false
        })
    }
  }

  var event: Event?
  var team: Team?
  var stepsBadges = [Badge]()
  var achievementBadges = [Badge]()
  var streakBadge : Badge?
  var teamProgressBadge : Badge?
  var personalProgressBadge : Badge?
  var finalMedalBadge : Badge?
  var isChallengeCompleted : Bool = false
  var cells: [[CellContext]] = []

  func configure() {

    guard let event = event else {
        return
    }

    let now = Date()
    isChallengeCompleted = event.challengePhase.end < now
    isChallengeCompleted = true

    /// Removing all earlier cells during refereh()
    stepsBadges.removeAll()
    achievementBadges.removeAll()

    /// Configure DailySteps , Streak  and Personal Prpgress badges
    configureBadges()

    /// Configure Team Progress badge
    configureTeamProgressBadge()
    
    if let badge = streakBadge {
      achievementBadges.append(badge)
    }
    if let badge = personalProgressBadge {
      achievementBadges.append(badge)
    }
    if let badge = teamProgressBadge {
      achievementBadges.append(badge)
    }
  }

  func configureBadges() {

    var badgesCount = 0
    var totalSteps = 0

    guard let records = records else { return }

    for record in records {

      if let distance = record.distance {

        /// Check for Daily Steps Badges
        switch distance {
        case EligibiltyRange.completed_daily_10000_Steps.range:
          badgesCount += 1
          createStepBadge(for: 10000, date: record.date)
          break
        case EligibiltyRange.completed_daily_15000_Steps.range:
          badgesCount += 1
          createStepBadge(for: 15000, date: record.date)
          break
        case EligibiltyRange.completed_daily_20000_Steps.range:
          badgesCount += 1
          createStepBadge(for: 20000, date: record.date)
          break
        case EligibiltyRange.completed_daily_25000_Steps.range:
          badgesCount += 1
          createStepBadge(for: 25000, date: record.date)
          break
        default:
          break
        }

        /// Check for Streak Badge
        switch badgesCount {
          /*
           Using the guard statement to avoid same badge creation again inorder to hold the first date value when the user crossed the respective range
          */
        case 10:
          guard let badge = personalProgressBadge, badge.streak == 10 else {
            createStreakBadge(for: 10, date: record.date)
            break
          }
          break
        case 20:
          guard let badge = personalProgressBadge, badge.streak == 20 else {
            createStreakBadge(for: 20, date : record.date)
            break
          }
          break
        case 30:
          guard let badge = personalProgressBadge, badge.streak == 30 else {
            createStreakBadge(for: 30, date : record.date)
            break
          }
          break
        case 40:
          guard let badge = personalProgressBadge, badge.streak == 40 else {
            createStreakBadge(for: 40, date : record.date)
            break
          }
          break
        case 50:
          guard let badge = personalProgressBadge, badge.streak == 50 else {
            createStreakBadge(for: 50, date : record.date)
            break
          }
          break
        case 60:
          guard let badge = personalProgressBadge, badge.streak == 60 else {
            createStreakBadge(for: 60, date : record.date)
            break
          }
          break
        case 70:
          guard let badge = personalProgressBadge, badge.streak == 70 else {
            createStreakBadge(for: 70, date : record.date)
            break
          }
          break
        case 80:
          guard let badge = personalProgressBadge, badge.streak == 80 else {
            createStreakBadge(for: 80, date : record.date)
            break
          }
          break
        case 90:
          guard let badge = personalProgressBadge, badge.streak == 90 else {
            createStreakBadge(for: 90, date : record.date)
            break
          }
          break
        default:
          break
        }

        /// Check for Personal Progress Badge
        totalSteps += distance
        switch totalSteps {
          /*
           Using the guard statement to avoid same badge creation again inorder to hold the first date value when the user crossed the respective range
          */
        case EligibiltyRange.completed_50_miles.range:
          guard let badge = personalProgressBadge, badge.personalProgress == 50 else {
            createPersonalProgressBadge(for: 50, date: record.date)
            break
          }
          break
        case EligibiltyRange.completed_100_Miles.range:
          guard let badge = personalProgressBadge, badge.personalProgress == 100 else {
            createPersonalProgressBadge(for: 100, date: record.date)
            break
          }
          break
        case EligibiltyRange.completed_250_Miles.range:
          guard let badge = personalProgressBadge, badge.personalProgress == 250 else{
            createPersonalProgressBadge(for: 250, date: record.date)
            break
          }
          break
        case EligibiltyRange.completed_500_miles.range:
          guard let badge = personalProgressBadge, badge.personalProgress == 500 else {
            createPersonalProgressBadge(for: 500, date: record.date)
            break
          }
          break
        default:
          break
        }
      }
    }

    /// Check for Final Medal Badge
    if isChallengeCompleted {
        switch badgesCount {
        case 25..<50:
          createFinalMedalBadge(for: FinalMedalType.silver)
          break
        case 50..<75:
          createFinalMedalBadge(for: FinalMedalType.gold)
          break
        case 75..<99:
          createFinalMedalBadge(for: FinalMedalType.platinum)
          break
        case 100:
          createFinalMedalBadge(for: FinalMedalType.champion)
          break
        default:
          break
        }
    }
  }

  /// Calculating Team Progress Badge
  func configureTeamProgressBadge() {
    guard let team = team else { return }
    var teamTotalSteps = 0
    for participant in team.members {
      guard let records = participant.records else { return }
      teamTotalSteps = teamTotalSteps + records.reduce(0) { $0 + ($1.distance ?? 0) }
    }
      switch teamTotalSteps {
      case EligibiltyRange.completed_25percent_journey.range:
        createTeamProgressBadge(for: 25)
        break
      case EligibiltyRange.completed_50percent_journey.range:
        createTeamProgressBadge(for: 50)
        break
      case EligibiltyRange.completed_75percent_journey.range:
        createTeamProgressBadge(for: 75)
        break
      default:
        break
      }
  }

  func createFinalMedalBadge(for medal: FinalMedalType) {
    finalMedalBadge = Badge(finalMedalAchieved: medal, badgeType: .finalMedal)
  }

  func createStepBadge(for steps: Int,date recordDate : Date?) {
    let newBadge = Badge(stepsCompleted: steps, date: recordDate, badgeType: .steps)
    stepsBadges.append(newBadge)
  }

  func createTeamProgressBadge(for percentage: Int) {
    teamProgressBadge = Badge(teamProgress: percentage, badgeType: .teamProgress)
  }

  func createPersonalProgressBadge(for miles: Int, date recordDate : Date?) {
    personalProgressBadge = Badge(personalProgress: miles, date: recordDate, badgeType: .personalProgress)
  }

  func createStreakBadge(for streak: Int, date recordDate : Date?){
    stepsBadges.removeAll()
    streakBadge = Badge(streak: streak, date: recordDate, badgeType: .streak)
  }

  func reload(completion: @escaping () -> Void) {

    self.completion = completion
    AKFCausesService.getParticipant(fbid: FacebookService.shared.id) { (result) in
      if let participant = Participant(json: result.response), let records = participant.records {
        self.records = records
        self.configure()
        completion()
      } else {
        completion()
      }
    }
  }
}