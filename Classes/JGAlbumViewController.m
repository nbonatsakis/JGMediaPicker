//
//  JGAlbumViewController.m
//  JGMediaBrowser
//
//  Created by Jamin Guy on 12/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "JGAlbumViewController.h"

#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVAsset.h>

#import "MPMediaItem+JGExtensions.h"
#import "MPMediaItemCollection+JGExtensions.h"
#import "JGAlbumTrackTableViewCell.h"

@interface JGAlbumViewController ()

- (void)updateUI;

@end

@implementation JGAlbumViewController

#define kSeparatorColor [UIColor colorWithRed:236.0/255.0 green:236.0/255.0 blue:236.0/255.0 alpha:1.0]
#define kGrayBackgroundColor [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1.0]

@synthesize albumArtImageView;
@synthesize albumArtistLabel;
@synthesize albumTitleLabel;
@synthesize albumReleaseDateLabel;
@synthesize albumTrackCountTimeLabel;
@synthesize albumTrackTableViewCell;

@synthesize delegate;
@synthesize albumCollection;
@synthesize showsCancelButton;
@synthesize allowsSelectionOfNonPlayableItem;
@synthesize upperView;
@synthesize allowsPickingMultipleItems;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.allowsPickingMultipleItems) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonTap:)];
        
        self.upperView.frame = CGRectMake(0.f, 0.f, self.upperView.bounds.size.width, self.upperView.bounds.size.height + 74.f);
        
        UIButton* addAllButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        addAllButton.frame = CGRectMake(10.f, self.upperView.bounds.size.height - 59.f, self.view.bounds.size.width - 20.f, 44.f);
        [addAllButton setTitle:@"Add all items" forState:UIControlStateNormal];
        [addAllButton.titleLabel setFont:[UIFont boldSystemFontOfSize:25.f]];
        [addAllButton addTarget:self action:@selector(addAllButtonTap:) forControlEvents:UIControlEventTouchUpInside];
        addAllButton.userInteractionEnabled = YES;
        addAllButton.enabled = YES;
        [self.upperView addSubview:addAllButton];
        NSLog(@"U:%@ B:%@", self.upperView, addAllButton);
    } else if(self.showsCancelButton) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self.delegate action:@selector(notifyDelegateOfCancellation)];
    }

    self.tableView.tableHeaderView = self.upperView;
    
    [[self tableView] setSeparatorColor:kSeparatorColor];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaLibraryDidChange:) name:MPMediaLibraryDidChangeNotification object:nil];
    [[MPMediaLibrary defaultMediaLibrary] beginGeneratingLibraryChangeNotifications];
}

- (void)viewDidUnload
{
    [self setAlbumArtImageView:nil];
    [self setAlbumArtistLabel:nil];
    [self setAlbumTitleLabel:nil];
    [self setAlbumReleaseDateLabel:nil];
    [self setAlbumTrackCountTimeLabel:nil];
    [[MPMediaLibrary defaultMediaLibrary] endGeneratingLibraryChangeNotifications];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateUI];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void) doneButtonTap:(id)sender {
    if ([self.delegate respondsToSelector:@selector(jgAlbumViewControllerDidFinish:)]) {
        [self.delegate jgAlbumViewControllerDidFinish:self];
    }
}

- (void) addAllButtonTap:(id)sender {
    for (MPMediaItem* mediaItem in self.albumCollection.items) {
        if (!self.allowsSelectionOfNonPlayableItem && ![mediaItem isPlayable]) {
            continue;
        }

        NSString*pId = [mediaItem valueForProperty:MPMediaItemPropertyPersistentID];
        [self.selectedMediaItems setObject:mediaItem forKey:pId];
        [[self.selectedMediaItems objectForKey:@"mediaSet"] addObject:mediaItem];
    }
    [self.tableView reloadData];
}


- (void) notifyDelegateOfDone {
    if ([self.delegate respondsToSelector:@selector(jgAlbumViewControllerDidFinish:)]) {
        [self.delegate jgAlbumViewControllerDidFinish:self];
    }
}

- (void)updateUI {
    MPMediaItem *mediaItem = [[self albumCollection] representativeItem];
    if(mediaItem) {
        self.title = [mediaItem artist];
        self.albumArtistLabel.text = [mediaItem artist];
        self.albumTitleLabel.text = [mediaItem albumTitle];
        self.albumArtImageView.image = [mediaItem artworkWithSize:self.albumArtImageView.bounds.size] ?: [UIImage imageNamed:@"AlbumArtPlaceholderLarge.png"];
        
        NSString *yearString = [mediaItem releaseYearString];
        self.albumReleaseDateLabel.text = yearString ? [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Released", @"Released"), yearString] : nil;
        NSNumber *totalTimeInSeconds = [[self albumCollection] playbackLength];
        NSInteger totalTimeInMinutes = (NSInteger)[totalTimeInSeconds doubleValue] / 60;
        self.albumTrackCountTimeLabel.text = [NSString stringWithFormat:@"%d %@, %d Mins.", self.albumCollection.count, NSLocalizedString(@"Songs", @"Songs"), totalTimeInMinutes];
    }
}

- (void)setAlbumCollection:(MPMediaItemCollection *)newAlbumCollection {
    if(newAlbumCollection != albumCollection) {
        albumCollection = newAlbumCollection;
        [self.tableView reloadData];
        [self updateUI];
    }
}

- (void)mediaLibraryDidChange:(NSNotification *)notification {
    [self updateUI];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.albumCollection.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"AlbumTrackCell";
    JGAlbumTrackTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        [[NSBundle mainBundle] loadNibNamed:@"JGAlbumTrackTableViewCell" owner:self options:nil];
        cell = self.albumTrackTableViewCell;
        self.albumTrackTableViewCell = nil;
    }
    
    MPMediaItem *mediaItem = [[[self albumCollection] items] objectAtIndex:indexPath.row];
    cell.trackNumberLabel.text = [NSString stringWithFormat:@"%d",[[mediaItem trackNumber] intValue]];
    cell.trackNameLabel.text = [mediaItem title];
    cell.trackLengthLabel.text = [mediaItem trackLengthString];
    if (!self.allowsSelectionOfNonPlayableItem && ![mediaItem isPlayable]) {
        cell.trackNameLabel.textColor = [UIColor lightGrayColor];
        cell.userInteractionEnabled = NO;
    }
    
    NSString*pId = [mediaItem valueForProperty:MPMediaItemPropertyPersistentID];
    if (self.allowsPickingMultipleItems && [self.selectedMediaItems objectForKey:pId]) {
        cell.trackNumberLabel.textColor = [UIColor lightGrayColor];
        cell.trackNameLabel.textColor = [UIColor lightGrayColor];
        cell.trackLengthLabel.textColor = [UIColor lightGrayColor];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }

    
    //make odd rows gray
    cell.backgroundView.backgroundColor = indexPath.row % 2 != 0 ? kGrayBackgroundColor : [UIColor whiteColor];

    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MPMediaItem *selectedItem = [self.albumCollection.items objectAtIndex:indexPath.row];
    
    // multi select
    if (self.allowsPickingMultipleItems) {
        NSString*pId = [selectedItem valueForProperty:MPMediaItemPropertyPersistentID];
        [self.selectedMediaItems setObject:selectedItem forKey:pId];
        [[self.selectedMediaItems objectForKey:@"mediaSet"] addObject:selectedItem];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        JGAlbumTrackTableViewCell* cell = (JGAlbumTrackTableViewCell*) [tableView cellForRowAtIndexPath:indexPath];
        cell.trackNumberLabel.textColor = [UIColor lightGrayColor];
        cell.trackNameLabel.textColor = [UIColor lightGrayColor];
        cell.trackLengthLabel.textColor = [UIColor lightGrayColor];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }

    
    if([self.delegate respondsToSelector:@selector(jgAlbumViewController:didPickMediaItems:selectedItem:)]) {
        [self.delegate jgAlbumViewController:self didPickMediaItems:self.albumCollection selectedItem:selectedItem];
    }
}

@end
