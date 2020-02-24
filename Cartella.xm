//I needed some more practice, so heres (kinda, not really anymore) simple but
//fun tweak! Cartella means Folder in Italian.
//A huge thanks to developers of awesome tweaks like Dayn, they motivate me to
//learn to code!

//I use layoutSubviews a lot here, I read that it was not the most optimal way
//of doing things, but I don't know what would be better in this case.

//If you have any optimization sugestions, or just sugestions in general, please
//do give them. (I annotate my code to explain my reasons for doing things)

#import <Cephei/HBPreferences.h> //Sorry if you don't like Cephei (kritanta)
#import "Cartella.h"

%group UniversalCode

%hook SBIconLegibilityLabelView
- (void)setHidden:(BOOL)arg1 {
  %orig(hideLabels); //If this is toggled, will return YES.
}
%end

%hook SBFloatyFolderView //Nothing that libFLEX can't find!
-(void)setBackgroundAlpha:(CGFloat)arg1 {
  if (hideFolderBackground) {
    %orig(0.0);
  } else {
    return (%orig);
  }
}

-(BOOL)_tapToCloseGestureRecognizer:(id)arg1 shouldReceiveTouch:(id)arg2 {
  %orig;
  if ((closeByOption == 2) || (closeByOption == 0)) {
    return (YES);
  } else {
    return %orig;
  }
}

%end

%hook SBFolderController
-(BOOL)_homescreenAndDockShouldFade {
  if (boldersLook) {
    return YES;
  } else {
    return %orig;
  }
}
%end

%end

%group iOS13

%hook SBIconListGridLayoutConfiguration

%property (nonatomic, assign) NSString *isFolder; //I'll make this a BOOL when I'm not lazy.

%new
-(NSString *)getLocations {
  //Let's first check to make sure "isFolder" hasn't been set (so no loops)
  if (self.isFolder != nil) {
    return self.isFolder;
  }
  //This is based on kritanta's method, but slightly different so home plus can work with Cartella
  //Ok, lets see. The iphonedevwiki says this is the format for MSHookIvar:
  //type ivar = MSHookIvar<type>(object, ivar_name);
  NSUInteger locationColumns = MSHookIvar<NSUInteger>(self, "_numberOfPortraitColumns");
  NSUInteger locationRows = MSHookIvar<NSUInteger>(self, "_numberOfPortraitRows");
  //Now we can use logic to figure out if its in a folder.
  if (locationColumns == 3 && locationRows == 3) {
    self.isFolder = @"YES"; //I'm pretty sure I SHOULD use the @, its an objc string. Also, I should use a bool.
  } else {
    self.isFolder = @"NO";
  }
  return self.isFolder;
} //Very similar to what I did in dockify.

-(NSUInteger)numberOfPortraitColumns {
  [self getLocations];
  if ([self.isFolder isEqualToString:@"YES"]) {
    return (folderColumns);
  } else {
    return (%orig);
  }
}

-(NSUInteger)numberOfPortraitRows {
  [self getLocations];
  if ([self.isFolder isEqualToString:@"YES"]) {
    return (folderRows);
  } else {
    return (%orig);
  }
}

- (UIEdgeInsets)portraitLayoutInsets {
  [self getLocations];
  if (fullScreen && hideFolderBackground) {
    if ([self.isFolder isEqualToString:@"YES"]) {
      UIEdgeInsets original = %orig;
      return UIEdgeInsetsMake(
        (original.top),
        (original.left/2), //no sense in wasting space if the background is hidden, so it won't look ugly.
        (original.bottom),
        (original.right/2)
      );
    } else {
      return (%orig);
    }
  } else {
    return (%orig);
  }
}

%end

%hook SBHFloatyFolderVisualConfiguration

-(CGSize)contentBackgroundSize {
  if (fullScreen) { //So we don't adjust anything if it's not set to fullScreen
    CGSize original = %orig;
    return CGSizeMake(
      ((original.width*1.15) - sideOffset),
      (original.height*1.6 - topOffset)
    );
  } else {
    return (%orig);
  }
}

-(CGFloat)continuousCornerRadius {
  return ((fullScreen && hideFolderBackground) ? 0 : (%orig));
}

%end
%hook SBFolderTitleTextField

-(void)layoutSubviews {
  %orig;
  if (boldText) {
    UIFont *regular = self.font;
    self.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:(regular.pointSize)];
    //Bolders used HelveticaNeue, so it looks exactly like Bolders did!
    //I had to look at UIFont.h to find the property pointSize (it's a CGFloat)
  }
  if (textAlignment != 1) {
    [self setTextCentersHorizontally:NO];
    if (textAlignment != 0) {
      [self setTextAlignment:textAlignment];
    }
  }
}

-(void)setFontSize:(double)arg1 {
  if (titleStyle == 1) {
    %orig(55);
  } else if (titleStyle == 2) {
    %orig(0);
  } else {
    %orig(40); //That's slightly more than the 36 iOS default.
  }
}

-(CGRect)textRectForBounds:(CGRect)arg1 {
  CGRect original = %orig;
  //This next part is a whole lot of proportions and mathsss
  if (fullScreen && isNotchedDevice) {
    return CGRectMake(
      ((original.origin.x * 0.14) - (sideOffset/2)),
      // I use (sideOffset/2) because the side pinch factor decreases the folder
      //box by sideOffset/2 on each side (left and right, the folder is pinned
      //in the center) The size of the folder box determines the text rect x
      //position, so I make sure to keep it pinned to the side anyways.
      ((titleStyle == 1) ? (topOffset - 25) : (topOffset - 15)),
      (original.size.width + (original.origin.x * 1.73)),
      //Don't make me explain this math
      (original.size.height)
    );
  } else if (fullScreen && (!isNotchedDevice)) {
    return CGRectMake(
      ((original.origin.x * 0.14) - (sideOffset/2)),
      ((titleStyle == 1) ? (topOffset - 80) : (topOffset - 60)), //this should fix things
      (original.size.width + (original.origin.x * 1.73)),
      (original.size.height)
    );
  } else {
    return CGRectMake(
      ((original.origin.x * 0.14) + 10),
      (original.origin.y + 100),
      (original.size.width + 40),
      (original.size.height)
    );
  }
}

%end

%hook UITextFieldBorderView //it seems this is for the edit folder text only, I hope so.
-(void)layoutSubviews {
  %orig;
  self.hidden = 1;
}
%end

%hook SBFolderControllerBackgroundView

//I'm only using layoutSubviews because its how I was taught, is easy, and will
//be easy for others to understand when they are reading my code.

-(void)layoutSubviews {
  if (blackOut) {
    self.backgroundColor = [UIColor colorWithRed:0.00 green:0.00 blue:0.00 alpha:1.0];
  } else if (noBlur) {
    self.alpha = 0;
  } else {
    %orig;
    self.alpha = 1;
  }
}
%end

%hook SBHFolderSettings

-(BOOL)pinchToClose {
  return (((closeByOption == 1) || (closeByOption == 0)) ? YES : (%orig));
}

%end

%hook SBFolderIconImageView

-(void)layoutSubviews { //I'm sorry for using layoutSubviews, there's probably a better way
  %orig; //I want to run the original stuff first
  if (hideIconBackground) {
    self.backgroundView.alpha = 0;
    self.backgroundView.hidden = 1;
  }
}

%end

%hook _SBIconGridWrapperView
//This is the folder icon... but the provider for the grid image only.
//This doesn't include the blur

-(void)layoutSubviews { //Tell me if there's a better way, please.
  %orig;
  CGAffineTransform originalIconView = (self.transform);
  self.transform = CGAffineTransformMake(
    setFolderIconSize,
    originalIconView.b,
    originalIconView.c,
    setFolderIconSize,
    originalIconView.tx,
    originalIconView.ty
  );
}

%end

%hook SBIconListPageControl

-(void)layoutSubviews {
  %orig;
  if (hideDots) {
    self.hidden = 1;
  }
}

%end
%end

%group iOS12 //There (mostly) isn't iOS 12 support, so I don't know why I include this stuff

%hook SBIconBlurryBackgroundView

-(BOOL)isBlurring {
  if (hideIconBackground) {
    return NO;
  } else {
    return %orig;
  }
}

%end

%hook SBFolderIconListView
+(unsigned long long)iconColumnsForInterfaceOrientation:(long long)arg1 {
  return (folderColumns);
}

+(NSUInteger)maxVisibleIconRowsInterfaceOrientation:(NSInteger)arg1 {
  return (folderRows);
}
%end

%end

static void reloadDynamics() { //This is called when the user selects the
                               //"Apply Dynamically" option in settings
  boldText = [preferences boolForKey:@"boldText"];
  setFolderIconSize = [preferences doubleForKey:@"setFolderIconSize"];
  hideIconBackground = [preferences boolForKey:@"hideIconBackground"];
  hideFolderBackground = [preferences boolForKey:@"hideFolderBackground"];
  boldersLook = [preferences boolForKey:@"boldersLook"];
  closeByOption = [preferences integerForKey:@"closeByOption"];
  blackOut = [preferences boolForKey:@"blackOut"];
  noBlur = [preferences boolForKey:@"noBlur"];
  fullScreen = [preferences boolForKey:@"fullScreen"];
  isNotchedDevice = [preferences boolForKey:@"isNotchedDevice"];
  if (!fullScreen) {
    [preferences setDouble:0 forKey:@"sideOffset"];
    [preferences setDouble:0 forKey:@"topOffset"];
  }
  sideOffset = [preferences doubleForKey:@"sideOffset"];
  topOffset = [preferences doubleForKey:@"topOffset"];
  titleStyle = [preferences integerForKey:@"titleStyle"];
  textAlignment = [preferences integerForKey:@"textAlignment"];
}

%ctor {
  CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reloadDynamics, CFSTR("com.burritoz.cartella/reload"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);

  preferences = [[HBPreferences alloc] initWithIdentifier:@"com.burritoz.cartellaprefs"];
  [preferences registerDefaults:@ { //defaults for prefernces
		@"tweakEnabled" : @YES,
    @"hideLabels" : @NO,
    @"hideIconBackground" : @NO,
    @"hideFolderBackground" : @YES,
    @"folderRows" : @3,
    @"folderColumns" : @4,
    @"titleStyle" : @1,
    @"fullScreen" : @YES,
    @"closeByOption" : @3,
    @"topOffset" : @0,
    @"boldersLook" : @YES,
    @"setIconSize" : @NO,
    @"sideOffset" : @0,
    @"isNotchedDevice" : @YES,
    @"noBlur" : @NO,
    @"blackOut" : @NO,
    @"setFolderIconSize" : @1,
    @"hideDots" : @NO,
    @"textAlignment" : @1,
    @"boldText" : @YES,
	}];
	[preferences registerBool:&tweakEnabled default:YES forKey:@"tweakEnabled"];
  [preferences registerBool:&isNotchedDevice default:YES forKey:@"isNotchedDevice"];
  [preferences registerBool:&boldText default:YES forKey:@"boldText"];
  [preferences registerBool:&hideLabels default:NO forKey:@"hideLabels"];
  [preferences registerBool:&hideDots default:NO forKey:@"hideDots"];
  [preferences registerBool:&noBlur default:NO forKey:@"noBlur"];
  [preferences registerBool:&blackOut default:NO forKey:@"blackOut"];
  [preferences registerBool:&hideIconBackground default:NO forKey:@"hideIconBackground"];
  [preferences registerBool:&hideFolderBackground default:YES forKey:@"hideFolderBackground"];
  [preferences registerInteger:&folderRows default:3 forKey:@"folderRows"];
  [preferences registerInteger:&folderColumns default:4 forKey:@"folderColumns"];
  [preferences registerInteger:&titleStyle default:1 forKey:@"titleStyle"];
  [preferences registerInteger:&textAlignment default:1 forKey:@"textAlignment"];
  [preferences registerBool:&boldersLook default:YES forKey:@"boldersLook"];
  [preferences registerBool:&fullScreen default:YES forKey:@"fullScreen"];
  [preferences registerInteger:&closeByOption default:3 forKey:@"closeByOption"];
  [preferences registerDouble:&topOffset default:0 forKey:@"topOffset"];
  [preferences registerDouble:&sideOffset default:0 forKey:@"sideOffset"];
  [preferences registerDouble:&setFolderIconSize default:1 forKey:@"setFolderIconSize"];

  if (!fullScreen) {
    //Because we don't adjust the folder background size otherwise
    [preferences setDouble:0 forKey:@"sideOffset"];
    [preferences setDouble:0 forKey:@"topOffset"];
    sideOffset = [preferences doubleForKey:@"sideOffset"];
    topOffset = [preferences doubleForKey:@"topOffset"];
  }

	if (tweakEnabled) { //That way my tweak doesn't load if it doesn't need to
    %init(UniversalCode);
    if (kCFCoreFoundationVersionNumber < 1600) {
      %init(iOS12); //There actually is not ios12 support, mostly
    } else {
      %init(iOS13);
    }
  }
}