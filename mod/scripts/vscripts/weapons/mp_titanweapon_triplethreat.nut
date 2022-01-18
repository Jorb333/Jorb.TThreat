untyped

global function OnWeaponPrimaryAttack_weapon_triplethreat
global function OnProjectileCollision_weapon_triplethreat
global function Fire_Weapon_TripleThreat

#if SERVER
global function OnWeaponNpcPrimaryAttack_weapon_triplethreat
#endif // #if SERVER

const FUSE_TIME = 0.5 //Applies once the grenade has stuck to a surface.

var function OnWeaponPrimaryAttack_weapon_triplethreat(entity weapon, WeaponPrimaryAttackParams attackParams)
{
	Fire_Weapon_TripleThreat(weapon, attackParams, 0, 10)
	Fire_Weapon_TripleThreat(weapon, attackParams, 0, 30)
	Fire_Weapon_TripleThreat(weapon, attackParams, 0, 50)

}

var function Fire_Weapon_TripleThreat( entity weapon, WeaponPrimaryAttackParams attackParams, float x, float y )
{
	entity player = weapon.GetWeaponOwner()

	weapon.EmitWeaponNpcSound( LOUD_WEAPON_AI_SOUND_RADIUS_MP, 0.2 )
	//vector bulletVec = ApplyVectorSpread( attackParams.pos, player.GetAttackSpreadAngle() * 2.0 )
	//attackParams.pos = bulletVec

	vector upVec = AnglesToUp(attackParams.pos) * y 
	vector rightVec = AnglesToUp(attackParams.pos) * x 
	attackParams.pos = attackParams.pos + upVec + rightVec

	printt(attackParams.pos)

	if ( IsServer() || weapon.ShouldPredictProjectiles() )
	{
		vector offset = Vector( 30.0, 6.0, -4.0 )
		if ( weapon.IsWeaponInAds() )
			offset = Vector( 30.0, 0.0, -3.0 )
		vector attackPos = player.OffsetPositionFromView( attackParams[ "pos" ], offset )	// forward, right, up
		FireGrenade( weapon, attackParams )
	}
}

#if SERVER
var function OnWeaponNpcPrimaryAttack_weapon_triplethreat( entity weapon, WeaponPrimaryAttackParams attackParams )
{
	weapon.EmitWeaponNpcSound( LOUD_WEAPON_AI_SOUND_RADIUS_MP, 0.2 )
	FireGrenade( weapon, attackParams, true )
}
#endif // #if SERVER

function FireGrenade( entity weapon, WeaponPrimaryAttackParams attackParams, isNPCFiring = false )
{
	vector angularVelocity = Vector( RandomFloatRange( -1200, 1200 ), 100, 0 )

	int damageType = DF_RAGDOLL | DF_EXPLOSION

	entity nade = weapon.FireWeaponGrenade( attackParams.pos, attackParams.dir, angularVelocity, 0.0 , damageType, damageType, !isNPCFiring, true, false )

	if ( nade )
	{
		#if SERVER
			EmitSoundOnEntity( nade, "Weapon_softball_Grenade_Emitter" )
			Grenade_Init( nade, weapon )
		#else
			entity weaponOwner = weapon.GetWeaponOwner()
			SetTeam( nade, weaponOwner.GetTeam() )
		#endif
	}
}

void function OnProjectileCollision_weapon_triplethreat( entity projectile, vector pos, vector normal, entity hitEnt, int hitbox, bool isCritical )
{
	bool didStick = PlantSuperStickyGrenade( projectile, pos, normal, hitEnt, hitbox )
	if ( !didStick )
		return

	#if SERVER
		if ( IsAlive( hitEnt ) && hitEnt.IsPlayer() )
		{
			EmitSoundOnEntityOnlyToPlayer( projectile, hitEnt, "weapon_softball_grenade_attached_1P" )
			EmitSoundOnEntityExceptToPlayer( projectile, hitEnt, "weapon_softball_grenade_attached_3P" )
		}
		else
		{
			EmitSoundOnEntity( projectile, "weapon_softball_grenade_attached_3P" )
		}
		thread DetonateStickyAfterTime( projectile, FUSE_TIME, normal )
	#endif
}

#if SERVER
// need this so grenade can use the normal to explode
void function DetonateStickyAfterTime( entity projectile, float delay, vector normal )
{
	wait delay
	if ( IsValid( projectile ) )
		projectile.GrenadeExplode( normal )
}
#endif