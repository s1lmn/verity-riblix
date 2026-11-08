--!nonstrict
-- Every existing card belongs to one five-card collection. Drop odds are unchanged.
local A={Order={"friends","sky","gardens","water","home","party","travel","world"}}
A.Sets={
 friends={Name="Друзья Verity",Cards={1,11,13,29,39},Color="FF95C8",Decor="home_album_friends"},
 sky={Name="Истории неба",Cards={2,8,17,35,40},Color="B8ABFF",Decor="home_album_sky"},
 gardens={Name="Волшебные сады",Cards={3,16,24,28,30},Color="9AF1BC",Decor="home_album_gardens"},
 water={Name="Водные миры",Cards={9,10,22,36,38},Color="8CE7F8",Decor="home_album_water"},
 home={Name="Дом и мечты",Cards={7,12,15,26,37},Color="FFCE8A",Decor="home_album_home"},
 party={Name="Маленькие радости",Cards={4,14,19,21,23},Color="FFA3E1",Decor="home_album_party"},
 travel={Name="Большое путешествие",Cards={5,6,18,25,33},Color="99C8FF",Decor="home_album_travel"},
 world={Name="Разноцветный мир",Cards={20,27,31,32,34},Color="FFE59A",Decor="home_album_world"},
}
function A.Count(collection,id)
 local count=0;for _,card in A.Sets[id].Cards do if (collection[tostring(card)] or 0)>0 then count+=1 end end;return count
end
function A.Complete(collection)
 for _,id in A.Order do if A.Count(collection,id)<#A.Sets[id].Cards then return false end end;return true
end
return A
