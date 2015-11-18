classdef Ant
    properties
        prevLocation % Needed to link pheromone particles
        location % Position in absolute coordinates.
        velocityVector % Vector composed from Vr Vc Vk.
        carryingFood % Bool
        followingPheromonePath % Bool
        goingToNestDirectly % Bool
        landmarkRecognized % Bool
        viewRange % How far an ants can "see"
        pheromoneIntensityToFollow % From which intensity value the ant
                                   % starts to follow a pheromone path
        limitSearchDistance % After what distance from a landmark pattern
                            % stop to search.
        pheromoneIntensity % How intense is the pheromone particle released
        problemEncountered % String containing the type of problem
                          % encountered. Empty string means
                          % no problem encountered.
        pointNearbyToSearch % Encountered a problem, try to solve it near
                            % the theoretical right position.
        timeToSpendInSearch % Encountered a problem, how much waste time
                            % focus the search near the theoretical right
                            % position.
        confidenceRegion % Encountered a problem, how much go far to search.
        globalVector % Vector pointing directly to the nest
        phi % Part to implement the "global vector" in a more
            % realistic way. phi represent an angle.
        l   % The second part needed for what is described above.
            % l represent the total length walked till now.
        pathDirection % Third part. This is the direction in which
                      % the ants was walking, in absolute coordinates.
        storedLandmarksMap % A map from a landmark pattern to a 
                           % local angle to follow.
        lookingFor % String witch says what the ant is looking for.
        
        startangle % angle with ant leaves the nest
        
        previousPhi
        previousGlobalVector
        isLeavingNest  % prohibit returning directly to nest on leaving
        maxDistance % when global vector reaches this value, the ant returns to the nest
        lostPosition % when the ant want to get home, but wont find it, this is the place where global vector=0
        searchRadius % radius around lost distance in which the ant will be searching
        
        timer % time ellapsed since the ant has left the nest
        timerWNoise % timer with some white noise
       % returnTime % time after which the ant has to return to the nest
       % Neu wird die returnTime aus Distanz und Geschwindigkeit und
       % livingTime berechnet
        livingTime % time after which the ant dies of overheating
        timeLapseFactor
       
        

    end
    
    %-- NOTE: the non static methods requires always an argument.
    %-- This is because matlab passes secretely the istance on which
    %-- the method is called as an argument.
    %-- Thus the method looks like this: function my_method(this)
    %-- and the call to the method is: obj.my_method()
    methods
        
        
        
        
        % Needed to preallocate an array of ants.
        function antsArr = Ant(F)
            if nargin ~= 0 % Allow nargin == 0 syntax.
                m = size(F,1);
                n = size(F,2);
                antsArr(m,n) = Ant; % Preallocate object array.
            end
        end
          
        
        
        %the only function that should be called
   
        function this = performStep(this,ground,dt)
            eps = 1e-4;
            
            % a pause so that according to the timeLapseFactor a step in
            % realtime takes ONE second.
            pause(1*(this.timeLapseFactor)^(-1)-0.002);
            %don't know what this is good for, but won't work without
            this.velocityVector(1:2) = this.velocityVector(1:2)./norm(this.velocityVector(1:2));
            this.pathDirection = this.velocityVector(1:2);
            
            

            
            
         % ant dies if it's out for too long 
         if(this.timer >=this.livingTime)
           %delete(this);
           return;
         end

         
       % ant returns so that with the time for the way home the time
       % outside the nest doesnt exceed the maximal living time.     
         
         
         
         
         
         
         if this.velocityVector(3) > eps
             returnZeit =   (this.l)/(this.velocityVector(3));
                 else
             returnZeit=returnTime;
         end
      
           

     
       if (this.timerWNoise+returnZeit-this.livingTime) > eps 
        %if this.timer >= this.returnTime
                   this.lookingFor = 'nest';
            end

            % ant picks up food and set nest as target if its location is
            % at food source
     
            if strcmp(this.lookingFor, 'food') && norm(this.location-ground.foodSourceLocation) < eps               
                this.carryingFood = true;
                this.lookingFor = 'nest';
            end
    
            %  ant puts down food and set food source as target if its
            %  location is at nest
            if strcmp(this.lookingFor, 'nest') && norm(this.location-ground.nestLocation) < eps
               
                %this.setUp(ground)
                this.carryingFood = false;
                this.lookingFor = 'food';
                this = this.setUp(ground);
            end
        
            % ant goes directly to food source if it sees it
            % or performs a random step
            if strcmp(this.lookingFor, 'food')
                if norm(ground.foodSourceLocation-this.location) < this.viewRange
                    this = this.stepStraightTo(ground.foodSourceLocation,dt);
                else
                this = this.takeRandomStep(dt);
                end
            elseif strcmp(this.lookingFor, 'nest')
                this = this.returnHomeUsingPathIntegrator(ground, dt);
            end
            
                   
            this.timer = this.timer + dt;
            %Adding some white noise to the timer
            this.timerWNoise = this.timerWNoise + randn(1,1) +dt;
                                
            
            
            this = this.updateGlobalVector(ground);   
            
            
        end
  
        % This method update the location of the ant using velocity vector
        % information
        function this = updateLocation(this,dt)
            v = this.velocityVector(1:2);
            theta = vector2angle(v);
            yPart = sin(theta)*this.velocityVector(3)*dt;
            xPart = cos(theta)*this.velocityVector(3)*dt;
            this.prevLocation = this.location;
            this.location = this.location + [xPart;yPart];
        end
            
        % This method makes the ant do a step directly straight to some
        % point. If the target is in range, it stops there.
        function this = stepStraightTo(this,point,dt)
            v = point - this.location;
            if norm(v) < this.velocityVector(3)*dt
                this.prevLocation = this.location;
                this.location = point;
            else
                this.velocityVector(1:2) = v;
                this = this.updateLocation(dt);
            end
        end
        
        function this = followPheromonePath(this,ground,dt)
            [bool, particle] = ground.hasPheromoneInLocation(this.location);
            if bool
                if this.carryingFood
                    this.prevLocation = this.location;
                    this.location = particle.next.location;
                else
                    this.prevLocation = this.location;
                    this.location = particle.prev.location;
                end
            else
                this = this.randomWalkStep(ground,dt);
            end
        end
        
        % ant performs random step
        function this = takeRandomStep(this, dt)
           varphi = normrnd(0,1)*pi/8;
           this.velocityVector(1:2) = [cos(varphi) -sin(varphi) ; sin(varphi) cos(varphi)]*this.velocityVector(1:2);
           this = this.updateLocation(dt);
        end
        
        % This method release pheromone on the ground, in the current and
        % position.
        function ground = releasePheromone(this,ground)
            pheromoneParticle = PheromoneParticle;
            pheromoneParticle.location = this.location;
            if this.carryingFood || this.followingPheromonePath
                pheromoneParticle.intensity = this.pheromoneIntensity+100;
            else
                pheromoneParticle.intensity = this.pheromoneIntensity;
            end
            arr = ground.pheromoneParticles; % arr just to abbreviate next line
            [bool prevParticle positionInArray] = ground.hasPheromoneInLocation(pheromoneParticle.location);
            if bool
                newPheromoneParticle = ...
                    arr(positionInArray).mergeWhithParticle(pheromoneParticle);
                clear pheromoneParticle;
                arr(positionInArray) = newPheromoneParticle;
                ground.pheromoneParticles = arr;
            else
                [bool prevParticle positionInArray] = ground.hasPheromoneInLocation(this.prevLocation);
                prevParticle = prevParticle.setNext(pheromoneParticle);
                pheromoneParticle = pheromoneParticle.setPrev(prevParticle);
                arr(positionInArray) = prevParticle;
                ground.pheromoneParticles = [arr;pheromoneParticle];
            end
        end
        
        % This method updates the global vector after the ant moved.
        
        function this = updateGlobalVector(this, ground)
            
            % 
            %sleep(1-0.001);
            % store olvalues in case they have to be restored
            this.previousGlobalVector = this.globalVector;
            this.previousPhi = this.phi;
            
            % if near nest set global vector to zero
            if norm(ground.nestLocation-this.location) < this.viewRange   % divide by 10 in order for the local vector to not lag much behind
                this.l = 0;
                this.phi = vector2angle(this.velocityVector);
                this.isLeavingNest = 1;
            else       
                if this.isLeavingNest == 1
                    this.isLeavingNest = 0;
                    this.l = this.viewRange;
                    this.phi = vector2angle(this.location-ground.nestLocation);
                else
                    k = 4*10^(-5)*(360/(2*pi))^2; % fitting constant from paper transformed to radians
                    eps = 1e-6;
                    v = this.location-this.prevLocation;
                    currentL = norm(v);

                    % Implementation using a more realist model
                    oldDir = this.pathDirection;
                    % Needed by the first step
                    if isnan(vector2angle(oldDir))
                        delta = 0;
                        this.phi = vector2angle(v);
                    else
                        delta = vector2angle(v)-this.phi;
                        if abs(delta) > pi+eps %stumpfer winkel wird zu spitzem winkel konvertiert falls stumpf
                            
                            if (delta > pi)
                                delta = -(2*pi-delta);
                            else
                                delta = 2*pi+delta;
                            end
                            
                        end
                            
                    end
                    %this.phi = (this.l*this.phi+delta+this.phi*currentL)/(this.l+currentL);
                    if abs(this.l) > eps
                        this.phi = mod(this.phi+k*(pi+delta)*(pi-delta)*delta/this.l*currentL,2*pi);
                    end
                    this.l = this.l + currentL - abs(delta)/pi*2*currentL;
                    if ~this.goingToNestDirectly
                        this.globalVector = [cos(this.phi) ; sin(this.phi)]*this.l;
                    end
                    if (abs(this.l)>this.maxDistance)
                        this.lookingFor = 'nest';
                    end
                    % prohibit global vector from beeing an invalid number
                    if isnan(this.phi) || isinf(this.phi)
                        this.phi = this.previousPhi;
                    end
                    if isnan(this.globalVector(1)) || isnan(this.globalVector(2)) || isinf(this.globalVector(1)) || isinf(this.globalVector(2))
                        this.globalVector = this.previousGlobalVector;
                    end
                end
            end
        
        end
        
        % Navigate home using path integrator
        function this = returnHomeUsingPathIntegrator(this, ground, dt)
            % use visual landmarks to navigate with local vector if near
            % targetgit@github.com:dowerner/Desert_Ant_Adaptive_Orientation.git            
            
            if isnan(this.l)
                if norm(ground.nestLocation-this.location) < this.viewRange
                    this = this.stepStraightTo(ground.foodSourceLocation,dt);
                    this.lostPosition = nan;
                else
                    if isnan(this.lostPosition)
                        this.lostPosition = this.location;
                    end
                    this = this.lookAround(this.lostPosition,dt);
                end
            else
                if norm(ground.nestLocation-this.location) < this.viewRange
                    this = this.stepStraightTo(ground.nestLocation,dt);
                else
                    this = this.stepStraightTo(this.location-this.globalVector,dt);
                end
            end
        end
        
        % ant is searching in an area of radius 'searchRadius' 
        % and center 'center'
        function this = lookAround(this,center,dt)
            if norm(this.location-center) >= this.searchRadius
                this = this.stepStraightTo(center,dt);
            else
                this = this.takeRandomStep(dt);
            end           
        end
        
        
        
        % Build an ant
        function this = setUp(this,ground)
            v = ([rand;rand]).*2-1;
            v = v./norm(v);
            %v = [v;0.125];
            v = [v;1];
            this.maxDistance = 10;
            this.isLeavingNest = 1;
            this.startangle = vector2angle(v);
            thi.phi = vector2angle(v);
            this.velocityVector = v;
            this.carryingFood = 0;
            this.followingPheromonePath = 0;
            this.landmarkRecognized = false;
            this.viewRange = 2;
            this.pheromoneIntensity = 50;
            this.problemEncountered = '';
            this.globalVector = [0;0];
            this.storedLandmarksMap = [];
            this.lookingFor = 'food';
            this.prevLocation = nan;
            this.location = ground.nestLocation;
            this.pheromoneIntensityToFollow = 300;
            this.phi = vector2angle(this.velocityVector);
            this.l = 0;
            this.pathDirection = [0;0];
            this.goingToNestDirectly = false;
            this.storedLandmarksMap = Hashtable;
            this.lostPosition = nan;
            this.searchRadius = 4;
            this.timer = 0;
            this.timerWNoise = 0;
            this.livingTime = 300;
            this.timeLapseFactor=500;
            
        end
    end
end




