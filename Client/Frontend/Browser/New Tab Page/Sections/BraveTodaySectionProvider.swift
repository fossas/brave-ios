// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveUI

class BraveTodaySectionProvider: NSObject, NTPObservableSectionProvider {
    let dataSource: FeedDataSource
    var sectionDidChange: (() -> Void)?
    
    init(dataSource: FeedDataSource) {
        self.dataSource = dataSource
        super.init()
        
        self.dataSource.load { [weak self] in
            self?.sectionDidChange?()
        }
    }
    
    @objc private func tappedBraveTodaySettings() {
        
    }
    
    func registerCells(to collectionView: UICollectionView) {
        collectionView.register(FeedCardCell<BraveTodayWelcomeView>.self)
        collectionView.register(FeedCardCell<HeadlineCardView>.self)
        collectionView.register(FeedCardCell<SmallHeadlinePairCardView>.self)
        collectionView.register(FeedCardCell<VerticalFeedGroupView>.self)
        collectionView.register(FeedCardCell<HorizontalFeedGroupView>.self)
        collectionView.register(FeedCardCell<NumberedFeedGroupView>.self)
    }
    
    var landscapeBehavior: NTPLandscapeSizingBehavior {
        .fullWidth
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.cards.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return fittingSizeForCollectionView(collectionView, section: indexPath.section)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 20
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == 0 {
            return collectionView.dequeueReusableCell(for: indexPath) as FeedCardCell<BraveTodayWelcomeView>
        }
        
        guard let card = dataSource.cards[safe: indexPath.item - 1] else {
            assertionFailure()
            return UICollectionViewCell()
        }
        switch card {
        case .headline(let item):
            let cell = collectionView.dequeueReusableCell(for: indexPath) as FeedCardCell<HeadlineCardView>
            cell.content.feedView.setupWithItem(item)
            cell.content.actionHandler = { _, action in
                if action == .tapped {
                    print("Tapped Feed Headline with URL: \(item.url?.absoluteString ?? "<null>")")
                }
            }
            return cell
        case .headlinePair(let pair):
            let cell = collectionView.dequeueReusableCell(for: indexPath) as FeedCardCell<SmallHeadlinePairCardView>
            cell.content.smallHeadelineCardViews.left.feedView.setupWithItem(pair.0)
            cell.content.smallHeadelineCardViews.right.feedView.setupWithItem(pair.1)
            return cell
        case .group(let items, let title, let direction, let displayBrand):
            let groupView: FeedGroupView
            let cell: UICollectionViewCell
            switch direction {
            case .horizontal:
                let horizontalCell = collectionView.dequeueReusableCell(for: indexPath) as FeedCardCell<HorizontalFeedGroupView>
                groupView = horizontalCell.content
                cell = horizontalCell
            case .vertical:
                let verticalCell = collectionView.dequeueReusableCell(for: indexPath) as FeedCardCell<VerticalFeedGroupView>
                groupView = verticalCell.content
                cell = verticalCell
            @unknown default:
                assertionFailure()
                return UICollectionViewCell()
            }
            groupView.titleLabel.text = title
            groupView.titleLabel.isHidden = title.isEmpty
            zip(groupView.feedViews, items).forEach { (view, item) in
                view.setupWithItem(item)
            }
            if displayBrand {
                groupView.groupBrandImageView.sd_setImage(with: nil)
            } else {
                groupView.groupBrandImageView.image = nil
            }
            groupView.groupBrandImageView.isHidden = !displayBrand
            return cell
        case .numbered(let items, let title):
            let cell = collectionView.dequeueReusableCell(for: indexPath) as FeedCardCell<NumberedFeedGroupView>
            cell.content.titleLabel.text = title
            zip(cell.content.feedViews, items).forEach { (view, item) in
                view.setupWithItem(item)
            }
            return cell
        }
    }
}

extension FeedItemView {
    func setupWithItem(_ feedItem: FeedItem) {
        titleLabel.text = feedItem.title
        if #available(iOS 13, *) {
            dateLabel.text = RelativeDateTimeFormatter().localizedString(for: Date(), relativeTo: feedItem.publishTime)
        }
        thumbnailImageView.sd_setImage(with: feedItem.imageURL)
        if let logo = feedItem.publisherLogo {
            brandImageView.sd_setImage(with: logo)
        }
    }
}