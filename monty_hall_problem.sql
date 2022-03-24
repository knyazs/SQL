/*
=============================================
 Author:      Miljan Radovic
 Create date: 2022-03-24
 Description:
 The Monty Hall problem is a brain teaser, in the form of a probability puzzle, loosely based on the American television game show Let's Make a Deal and named after its original host, Monty Hall.
 The problem was originally posed (and solved) in a letter by Steve Selvin to the American Statistician in 1975.
 It became famous as a question from reader Craig F. Whitaker's letter quoted in Marilyn vos Savant's "Ask Marilyn" column in Parade magazine in 1990:
 Same code below simulates 100 games and gives result if player decides to stay with the door vs switch the door
=============================================
*/

declare @counter int = 0
declare @maxGames int = 100 -- the more games, the more precise calculation will be

declare @prizeDoor tinyint
declare @chosenDoor tinyint
declare @openedDoor tinyint

declare @winCountIfStay int = 0
declare @winCountIfSwitch int = 0

while @counter < @maxGames
begin
    -- Hosts put a prize behind random door 1-3
    SELECT @prizeDoor = ABS(CAST(NEWID() AS binary(6)) %3) + 1 FROM sysobjects

    -- Player randomly selects one door 1-3
    SELECT @chosenDoor = ABS(CAST(NEWID() AS binary(6)) %3) + 1 FROM sysobjects

    -- Host shows one door where there is no prize
    SELECT TOP 1 @openedDoor = Door
    FROM (select 1 as Door union all select 2 union all select 3) T
    WHERE T.Door not in (@prizeDoor, @chosenDoor)

	set @winCountIfStay += case when @prizeDoor = @chosenDoor then 1 else 0 end
	set @winCountIfSwitch += case when @prizeDoor = @chosenDoor then 0 else 1 end

	set @counter = @counter + 1
end

select
	1.0 * @winCountIfStay / (@winCountIfStay + @winCountIfSwitch) as winPcrIfStay,
	1.0 * @winCountIfSwitch / (@winCountIfStay + @winCountIfSwitch) as winPctIfSwitch
