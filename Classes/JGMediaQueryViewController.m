//
//  ItemsViewController.m
//  MusicBrowser
//
//  Created by Jamin Guy on 12/21/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "JGMediaQueryViewController.h"

#import <MediaPlayer/MediaPlayer.h>

#import "MPMediaItem+JGExtensions.h"
#import "MPMediaPlaylist+JGExtensions.h"
#import "JGAlbumViewController.h"

@interface JGMediaQueryViewController () 

@property (nonatomic, retain) NSArray *items;
@property (nonatomic, retain) NSArray *itemSections;

- (void)updateItems;

- (void)notifyDelegateOfSelection:(MPMediaItemCollection *)mediaItems selectedItem:(MPMediaItem *)selectedItem;
- (void)notifyDelegateOfCancellation;

@end

@implementation JGMediaQueryViewController

#define kPlaylistCellHeight 44.0
#define kAlbumCellHeight 55.0
#define kArtistCellHeight 44.0
#define kSongCellHeight 44.0
#define kAlbumArtSize CGSizeMake(110.0, 110.0)

#define kItemCountThresholdForTableViewSections 25

@synthesize itemTableView;
@synthesize items;
@synthesize itemSections;
@synthesize delegate;
@synthesize queryType;
@synthesize mediaQuery;
@synthesize showsCancelButton;
@synthesize allowsSelectionOfNonPlayableItem;
@synthesize allowsPickingMultipleItems;
@synthesize selectedMediaItems;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {        
    }
    return self;
}
							
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (void)setQueryType:(JGMediaQueryType)newQueryType {
    queryType = newQueryType;
    [self updateItems];
}

- (void)setMediaQuery:(MPMediaQuery *)newMediaQuery {
    if(mediaQuery != newMediaQuery) {
        mediaQuery = newMediaQuery;
        [self updateItems];
    }
}

- (void)updateItems {
    MPMediaQuery *query = self.mediaQuery;
    if(query) {
        switch (self.queryType) {
            //don't ever want sections for these types
            case JGMediaQueryTypePlaylists: 
            case JGMediaQueryTypeAlbumArtist: {
                self.items = [query collections];
                self.itemSections = nil;
            }break;
                
            //do wan't sections for these types if item count passes threshold
            case JGMediaQueryTypeArtists: 
            case JGMediaQueryTypeAlbums: 
            case JGMediaQueryTypeSongs: {
                self.items = [query collections];
                if(self.items.count > kItemCountThresholdForTableViewSections) {
                    self.itemSections = [query collectionSections];
                    if(self.itemSections.count <= 1) {
                        self.itemSections = nil;
                    }
                }
            }break;
                
            default:
                break;
        }
        
        [[self itemTableView] reloadData];
    }
}

- (void)notifyDelegateOfSelection:(MPMediaItemCollection *)mediaItems selectedItem:(MPMediaItem *)selectedItem {
    if([self.delegate respondsToSelector:@selector(jgMediaQueryViewController:didPickMediaItems:selectedItem:)]) {
        [self.delegate jgMediaQueryViewController:self didPickMediaItems:mediaItems selectedItem:selectedItem];
    }
}

- (void)notifyDelegateOfCancellation {
    if([self.delegate respondsToSelector:@selector(jgMediaQueryViewControllerDidCancel:)]) {
        [self.delegate jgMediaQueryViewControllerDidCancel:self];
    }
}

- (void) notifyDelegateOfDone {
    if ([self.delegate respondsToSelector:@selector(jgMediaQueryViewControllerDidFinish:)]) {
        [self.delegate jgMediaQueryViewControllerDidFinish:self];
    }
}

- (void)cancelButtonTap:(id)sender {
    [self notifyDelegateOfCancellation];
}

- (void) doneButtonTap:(id)sender {
    [self notifyDelegateOfDone];
}

- (void)mediaLibraryDidChange:(NSNotification *)notification {
    [self updateItems];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.allowsPickingMultipleItems) {
        if ([[self.navigationController.viewControllers objectAtIndex:0] isEqual:self]) {
            self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonTap:)];
        }
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonTap:)];
    
        if (self.queryType == JGMediaQueryTypeSongs) {
            self.itemTableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, self.view.bounds.size.width, 74.f)];
            self.itemTableView.tableHeaderView.userInteractionEnabled = YES;
            
            UIButton* addAllButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            addAllButton.frame = CGRectMake(10.f, 15.f, self.view.bounds.size.width - 20.f, 44.f);
            [addAllButton setTitle:@"Add all items" forState:UIControlStateNormal];
            [addAllButton.titleLabel setFont:[UIFont boldSystemFontOfSize:25.f]];
            [addAllButton addTarget:self action:@selector(addAllButtonTap:) forControlEvents:UIControlEventTouchUpInside];
            addAllButton.userInteractionEnabled = YES;
            addAllButton.enabled = YES;
            [self.itemTableView.tableHeaderView addSubview:addAllButton];
        }
    } else if(self.showsCancelButton) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonTap:)];
    } 
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaLibraryDidChange:) name:MPMediaLibraryDidChangeNotification object:nil];
    [[MPMediaLibrary defaultMediaLibrary] beginGeneratingLibraryChangeNotifications];
}

- (void)viewDidUnload {
    [self setItemTableView:nil];
    [[MPMediaLibrary defaultMediaLibrary] endGeneratingLibraryChangeNotifications];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[self itemTableView] deselectRowAtIndexPath:[[self itemTableView] indexPathForSelectedRow] animated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark - Table view data source

- (void) addAllButtonTap:(id)sender {
    for (MPMediaItemCollection* mediaItemCollection in self.items) {
        MPMediaItem *mediaItem = [mediaItemCollection representativeItem];
        NSString*pId = [mediaItem valueForProperty:MPMediaItemPropertyPersistentID];
        [self.selectedMediaItems setObject:mediaItem forKey:pId];
        [[self.selectedMediaItems objectForKey:@"mediaSet"] addObject:mediaItem];
    }
    [self.itemTableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger numberOfSections = self.itemSections.count;    
    return numberOfSections > 0 ? numberOfSections : 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *sectionTitle = nil;    
    if(self.itemSections.count) {
        MPMediaQuerySection *querySection = [[self itemSections] objectAtIndex:section];
        sectionTitle = querySection.title;
    }    
    return sectionTitle;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    NSMutableArray *sectionIndexTitles = nil;
    if(self.itemSections.count) {
        sectionIndexTitles = [NSMutableArray arrayWithCapacity:self.itemSections.count];
        [[self itemSections] enumerateObjectsUsingBlock:^(MPMediaQuerySection *querySection, NSUInteger idx, BOOL *stop) {
            [sectionIndexTitles addObject:[querySection title]];
        }];
    }
    return  sectionIndexTitles;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    __block NSInteger sectionIndex = 0;
    [[self itemSections] enumerateObjectsUsingBlock:^(MPMediaQuerySection *querySection, NSUInteger idx, BOOL *stop) {
        if([[querySection title] isEqualToString:title]) {
            sectionIndex = idx;
            *stop = YES;
        }
    }];
    
    return sectionIndex;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = self.items.count;
    if(self.itemSections.count) {
        MPMediaQuerySection *querySection = [[self itemSections] objectAtIndex:section];
        numberOfRows = querySection.range.length;
    }
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *PlaylistCellIdentifier = @"PlaylistCell";
    static NSString *ArtistCellIdentifier = @"ArtistCell";
    static NSString *AlbumCellIdentifier = @"AlbumCell";
    static NSString *SongCellIdentifier = @"SongCell";
    
    UITableViewCell *cell = nil;
    switch (self.queryType) {

        case JGMediaQueryTypePlaylists: {            
            cell = [tableView dequeueReusableCellWithIdentifier:PlaylistCellIdentifier];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:PlaylistCellIdentifier];        
            }
        }break;
            
        case JGMediaQueryTypeArtists: {
            cell = [tableView dequeueReusableCellWithIdentifier:ArtistCellIdentifier];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ArtistCellIdentifier];        
            }
        }break;
            
        case JGMediaQueryTypeAlbums:
        case JGMediaQueryTypeAlbumArtist: {
            cell = [tableView dequeueReusableCellWithIdentifier:AlbumCellIdentifier];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:AlbumCellIdentifier];        
            }
        }break;
            
        case JGMediaQueryTypeSongs: {
            cell = [tableView dequeueReusableCellWithIdentifier:SongCellIdentifier];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:SongCellIdentifier];        
            }
        }break;
            
        default:
            break;
    }

    NSInteger itemIndex = indexPath.row;
    if(self.itemSections.count) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        MPMediaQuerySection *querySection = [[self itemSections] objectAtIndex:indexPath.section];
        itemIndex = querySection.range.location + indexPath.row;        
    }
    else if(self.queryType == JGMediaQueryTypeSongs) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    MPMediaItemCollection *mediaItemCollection = [[self items] objectAtIndex:itemIndex];
    MPMediaItem *mediaItem = [mediaItemCollection representativeItem];
    
    switch (self.queryType) {
            
        case JGMediaQueryTypePlaylists: {
            MPMediaPlaylist *playlist = (MPMediaPlaylist *)mediaItemCollection;            
            [[cell textLabel] setText:[playlist name]];
        }break;
            
        case JGMediaQueryTypeArtists: {
            [[cell textLabel] setText:[mediaItem artist]];
        }break;
            
        case JGMediaQueryTypeAlbums:
        case JGMediaQueryTypeAlbumArtist: {
            [[cell textLabel] setText:[mediaItem albumTitle]];
            [[cell detailTextLabel] setText:[mediaItem albumArtist]];
            UIImage *albumImage = [mediaItem artworkWithSize:kAlbumArtSize] ?: [UIImage imageNamed:@"AlbumArtPlaceholder.png"];
            [[cell imageView] setImage:albumImage];
        }break;
            
        case JGMediaQueryTypeSongs: {
            [[cell textLabel] setText:[mediaItem title]];
            NSString *subTitle = [NSString stringWithFormat:@"%@ - %@", [mediaItem albumTitle], [mediaItem albumArtist]];
            [[cell detailTextLabel] setText:subTitle];
            
            if (!self.allowsSelectionOfNonPlayableItem && ![mediaItem isPlayable]) {
                cell.userInteractionEnabled = NO;
                for (UILabel *label in [NSArray arrayWithObjects:[cell textLabel], [cell detailTextLabel], nil]) {
                    label.textColor = [UIColor lightGrayColor];
                }
            }
            
            NSString*pId = [mediaItem valueForProperty:MPMediaItemPropertyPersistentID];
            if (self.allowsPickingMultipleItems && [self.selectedMediaItems objectForKey:pId]) {
                for (UILabel *label in [NSArray arrayWithObjects:[cell textLabel], [cell detailTextLabel], nil]) {
                    label.textColor = [UIColor lightGrayColor];
                }
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            
        }break;
            
        default:
            break;
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat height = 44.0;
    switch (self.queryType) {
        case JGMediaQueryTypePlaylists: {
            height = kPlaylistCellHeight;
        }break;
            
        case JGMediaQueryTypeArtists: {
            height = kArtistCellHeight;
        }break;
            
        case JGMediaQueryTypeAlbums:
        case JGMediaQueryTypeAlbumArtist: {
            height = kAlbumCellHeight;
        }break;
            
        case JGMediaQueryTypeSongs: {
            height = kSongCellHeight;
        }break;
    }
    return height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIViewController *viewController = nil;
    NSInteger itemIndex = indexPath.row;
    if(self.itemSections.count) {
        MPMediaQuerySection *querySection = [[self itemSections] objectAtIndex:indexPath.section];
        itemIndex = querySection.range.location + indexPath.row;        
    }
    
    switch (self.queryType) {
        case JGMediaQueryTypePlaylists: {
            MPMediaPlaylist *playlist = (MPMediaPlaylist *)[[self items] objectAtIndex:itemIndex];
            NSNumber *playlistPersistentID = [playlist persistentID];
            NSString *playlistName = [playlist name];
            
            MPMediaQuery *playlistQuery = [[MPMediaQuery alloc] init];
            MPMediaPropertyPredicate *predicate = [MPMediaPropertyPredicate predicateWithValue:playlistPersistentID forProperty:MPMediaPlaylistPropertyPersistentID comparisonType:MPMediaPredicateComparisonEqualTo];
            [playlistQuery addFilterPredicate:predicate];
            
            JGMediaQueryViewController *playlistViewController = [[JGMediaQueryViewController alloc] initWithNibName:@"JGMediaQueryViewController" bundle:nil];
            playlistViewController.showsCancelButton = YES;
            playlistViewController.allowsSelectionOfNonPlayableItem = self.allowsSelectionOfNonPlayableItem;
            playlistViewController.title = playlistName;
            playlistViewController.queryType = JGMediaQueryTypeSongs;
            playlistViewController.mediaQuery = playlistQuery;
            playlistViewController.delegate = self;
            playlistViewController.selectedMediaItems = self.selectedMediaItems;
            playlistViewController.allowsPickingMultipleItems = self.allowsPickingMultipleItems;
            viewController = playlistViewController;
        }break;
            
        case JGMediaQueryTypeArtists: {
            MPMediaItemCollection *mediaItemCollection = [[self items] objectAtIndex:itemIndex];
            NSString *artist = [[mediaItemCollection representativeItem] artist];
            MPMediaQuery *albumsQuery = [[MPMediaQuery alloc] init];
            MPMediaPropertyPredicate *predicate = [MPMediaPropertyPredicate predicateWithValue:artist forProperty:MPMediaItemPropertyArtist comparisonType:MPMediaPredicateComparisonEqualTo];
            [albumsQuery addFilterPredicate:predicate];
            albumsQuery.groupingType = MPMediaGroupingAlbum;
            
            JGMediaQueryViewController *albumsViewController = [[JGMediaQueryViewController alloc] initWithNibName:@"JGMediaQueryViewController" bundle:nil];
            albumsViewController.showsCancelButton = YES;
            albumsViewController.allowsSelectionOfNonPlayableItem = self.allowsSelectionOfNonPlayableItem;
            albumsViewController.title = artist;
            albumsViewController.queryType = JGMediaQueryTypeAlbums;
            albumsViewController.mediaQuery = albumsQuery;
            albumsViewController.delegate = self;
            albumsViewController.selectedMediaItems = self.selectedMediaItems;
            albumsViewController.allowsPickingMultipleItems = self.allowsPickingMultipleItems;
            viewController = albumsViewController;
        }break;
            
        case JGMediaQueryTypeSongs: {
            if([self.delegate respondsToSelector:@selector(jgMediaQueryViewController:didPickMediaItems:selectedItem:)]) {
                MPMediaItemCollection *selectedMediaItemCollection = [[self items] objectAtIndex:itemIndex];
                MPMediaItem *selectedMediaItem = [selectedMediaItemCollection representativeItem];

                NSMutableArray *songsArray = [NSMutableArray arrayWithCapacity:selectedMediaItemCollection.count];
                for (MPMediaItemCollection *mediaItemCollection in [self items]) {
                    [songsArray addObject:[mediaItemCollection representativeItem]];
                }
                MPMediaItemCollection *mediaItemCollection = [MPMediaItemCollection collectionWithItems:songsArray];
                [self.delegate jgMediaQueryViewController:self didPickMediaItems:mediaItemCollection selectedItem:selectedMediaItem];
                
                // multi select
                if (self.allowsPickingMultipleItems) {
                    NSString*pId = [selectedMediaItem valueForProperty:MPMediaItemPropertyPersistentID];
                    [self.selectedMediaItems setObject:selectedMediaItem forKey:pId];
                    [[self.selectedMediaItems objectForKey:@"mediaSet"] addObject:selectedMediaItem];
                    [tableView deselectRowAtIndexPath:indexPath animated:YES];
                    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
                    for (UILabel *label in [NSArray arrayWithObjects:[cell textLabel], [cell detailTextLabel], nil]) {
                        label.textColor = [UIColor lightGrayColor];
                    }
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                }
            }
        }break;
            
        case JGMediaQueryTypeAlbums:    
        case JGMediaQueryTypeAlbumArtist: {            
            JGAlbumViewController *albumViewController = [[JGAlbumViewController alloc] initWithNibName:@"JGAlbumViewController" bundle:nil];
            albumViewController.showsCancelButton = YES;
            albumViewController.allowsSelectionOfNonPlayableItem = self.allowsSelectionOfNonPlayableItem;
            albumViewController.allowsPickingMultipleItems = self.allowsPickingMultipleItems;
            albumViewController.selectedMediaItems = self.selectedMediaItems;
            MPMediaItemCollection *albumCollection = [[self items] objectAtIndex:itemIndex];
            albumViewController.delegate = self;
            albumViewController.albumCollection = albumCollection;
            viewController = albumViewController;
        }break;
            
        default:
            break;
    }
    
    if(viewController) {
        [[self navigationController] pushViewController:viewController animated:YES];
    }
     
}

#pragma mark - jgMediaQueryViewControllerDelegate callbacks
- (void)jgMediaQueryViewController:(JGMediaQueryViewController *)mediaQueryViewController didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection selectedItem:(MPMediaItem *)selectedItem {
    if([self.delegate respondsToSelector:@selector(jgMediaQueryViewController:didPickMediaItems:selectedItem:)]) {
        [self.delegate jgMediaQueryViewController:self didPickMediaItems:mediaItemCollection selectedItem:selectedItem];
    }
}

- (void)jgMediaQueryViewControllerDidCancel:(JGMediaQueryViewController *)mediaPicker {
    if([self.delegate respondsToSelector:@selector(jgMediaQueryViewControllerDidCancel:)]) {
        [self.delegate jgMediaQueryViewControllerDidCancel:self];
    }
}

- (void) jgMediaQueryViewControllerDidFinish:(JGMediaQueryViewController*)mediaPicker {
    [self notifyDelegateOfDone];
}

#pragma mark - JGAlbumViewControllerDelegate callback
- (void)jgAlbumViewController:(JGAlbumViewController *)albumViewController didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection selectedItem:(MPMediaItem *)selectedItem {
    [self notifyDelegateOfSelection:mediaItemCollection selectedItem:selectedItem];
}

- (void) jgAlbumViewControllerDidFinish:(JGAlbumViewController*)albumController {
    [self notifyDelegateOfDone];
}

@end
